# frozen_string_literal: true

module DownloadManager
  class ParallelDownloadQueue
    DOWNLOAD_MAX_PARALLEL = ENV.fetch('DOWNLOAD_MAX_PARALLEL') { 10 }

    # Raised when the write path cannot be confined to the export directory (path
    # traversal via `..` or an absolute path in an attacker-controlled template).
    class PathTraversalError < StandardError; end

    attr_accessor :attachments,
                  :destination,
                  :on_error

    def initialize(attachments, destination)
      @attachments = attachments
      # expanded once, so the confinement check below compares two paths built the
      # same way, and a relative destination cannot re-resolve if cwd moves
      @destination = Pathname.new(destination).expand_path
      @open_files = Set.new
    end

    def download_all
      hydra = Typhoeus::Hydra.new(max_concurrency: DOWNLOAD_MAX_PARALLEL)

      attachments.each do |attachment, path|
        download_one(attachment: attachment,
                      path_in_download_dir: path,
                      http_client: hydra)
      rescue => e
        on_error.call(attachment, path, e)
      end

      hydra.run
    ensure
      # left open when the hydra is interrupted before their on_complete
      @open_files.each do |file|
        file.close
      rescue IOError, SystemCallError
        # keep closing the others and let the original exception propagate
      end
      @open_files.clear
    end

    # can't be used with typhoeus, otherwise block is closed before the request is run by hydra
    def download_one(attachment:, path_in_download_dir:, http_client:)
      attachment_path = confined_attachment_path(path_in_download_dir)

      attachment_path.dirname.mkpath # defensive, do not write in undefined dir

      if attachment.is_a?(ActiveStorage::FakeAttachment)
        attachment_path.write(attachment.file.read, mode: 'wb')
        return
      end

      request = Typhoeus::Request.new(attachment.url)
      if attachment.blob.byte_size < 10.megabytes
        request_in_whole(request, attachment:, attachment_path:, path_in_download_dir:)
      else
        request_in_chunks(request, attachment:, attachment_path:, path_in_download_dir:)
      end

      http_client.queue(request)
    end

    private

    # `path_in_download_dir` comes from a user-controlled export template
    # (`ExportTemplate#attachment_path`), whose tags are substituted without
    # escaping: both the directory part and the basename can carry hostile input.
    # So we rebuild the path from explicitly filtered components — sanitizing every
    # one of them, not just the basename — rather than let `Pathname#join`/
    # `expand_path` resolve it for us:
    #   - an absolute path would replace the `destination` prefix entirely
    #   - a `..` that would climb out of the export dir is refused loudly, so a real
    #     escape attempt stays visible (logged, reported, listed in the error report)
    #     instead of being silently relocated somewhere inside the export
    #   - a `..` absorbed within the export dir is dropped rather than resolved:
    #     resolving it would collapse two paths that
    #     `DownloadableFileService.deduplicate_paths` believes to be distinct onto
    #     the same file. Dropping it keeps the attachment, under its own directory.
    #
    # The final check is an exact structural equality, not a prefix comparison: we
    # require the expanded path to be *literally* the export dir followed by the
    # components we chose. Comparing `..` against the literal string is not enough,
    # because `File.expand_path` honours spellings a string comparison misses, and
    # which ones it honours is platform dependent: on macOS it strips a leading
    # UTF-8 BOM, so a component of "﻿.." traverses like ".." (on Linux it stays a
    # plain directory name). Resolving it there would collapse two paths that
    # `DownloadableFileService.deduplicate_paths` believes to be distinct onto the
    # same file.
    #
    # The equality makes us safe on every platform without having to enumerate those
    # spellings: either `expand_path` normalises something and the two sides differ,
    # so we refuse, or it does not and the path is literally the export dir followed
    # by sanitized components (which can no longer contain a separator), hence
    # confined by construction. It also subsumes the sibling-directory case
    # (`/tmp/export-evil` vs `/tmp/export`), and a basename that is empty or is
    # itself `.`/`..` — none of those survive `expand_path` intact either.
    def confined_attachment_path(path_in_download_dir)
      path = Pathname.new(path_in_download_dir)

      raise PathTraversalError, "refusing an absolute path: #{path_in_download_dir.inspect}" if path.absolute?

      relative_path = File.join(
        *confined_dir_components(path.dirname, path_in_download_dir),
        sanitize_filename(path.basename.to_s)
      )
      expected = File.join(destination.to_s, relative_path)
      resolved = destination.join(relative_path).expand_path

      if resolved.to_s != expected
        raise PathTraversalError, "refusing to write outside export dir: #{path_in_download_dir.inspect}"
      end

      resolved
    end

    # Walks the directory components once, tracking the depth relative to the export
    # dir with `..` popping it: a depth going negative means the path climbs out and
    # is refused. Otherwise `.`/`..` are dropped (not popped, see
    # `confined_attachment_path`) and each remaining component is sanitized.
    def confined_dir_components(dirname, path_in_download_dir)
      depth = 0

      dirname.each_filename.filter_map do |component|
        next if component == '.'

        if component == '..'
          depth -= 1
          if depth.negative?
            raise PathTraversalError, "refusing to write outside export dir: #{path_in_download_dir.inspect}"
          end

          next
        end

        depth += 1
        sanitize_filename(component).presence
      end
    end

    def sanitize_filename(original_filename)
      filename = ActiveStorage::Filename.new(original_filename).sanitized

      return filename if filename.bytesize <= 255

      ext = File.extname(filename)
      basename = File.basename(filename, ext).byteslice(0, 255 - ext.bytesize)

      basename + ext
    end

    def request_in_whole(request, attachment:, attachment_path:, path_in_download_dir:)
      request.on_complete do |response|
        if response.success?
          attachment_path.open(mode: 'wb') do |fd|
            fd.write(response.body)
          end
        else
          handle_response_error(response.code, attachment:, attachment_path:, path_in_download_dir:)
        end
      end
    end

    # opened on the first chunk: download_all queues every request before the hydra runs
    def request_in_chunks(request, attachment:, attachment_path:, path_in_download_dir:)
      downloaded_file = nil
      file_error = nil

      # raising inside a curl callback would abort the whole hydra: report this attachment only
      request.on_body do |chunk|
        downloaded_file ||= attachment_path.open(mode: 'wb').tap { @open_files << it }
        downloaded_file.write(chunk)
      rescue SystemCallError, IOError => e
        file_error = e
        :abort
      end

      request.on_complete do |response|
        if downloaded_file
          downloaded_file.close
          @open_files.delete(downloaded_file)
        end

        if file_error || !response.success?
          handle_response_error(file_error || response.code, attachment:, attachment_path:, path_in_download_dir:)
        elsif downloaded_file.nil?
          attachment_path.write('', mode: 'wb') # libcurl yields no chunk for an empty body
        end
      end
    end

    def handle_response_error(error, attachment:, attachment_path:, path_in_download_dir:)
      attachment_path.delete if attachment_path.exist? # -> case of retries failed, must cleanup partialy downloaded file
      on_error.call(attachment, path_in_download_dir, error)
    end
  end
end
