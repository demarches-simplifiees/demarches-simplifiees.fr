# frozen_string_literal: true

module DownloadManager
  class ParallelDownloadQueue
    DOWNLOAD_MAX_PARALLEL = ENV.fetch('DOWNLOAD_MAX_PARALLEL') { 10 }

    attr_accessor :attachments,
                  :destination,
                  :on_error

    def initialize(attachments, destination)
      @attachments = attachments
      @destination = Pathname.new(destination)
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
    end

    # can't be used with typhoeus, otherwise block is closed before the request is run by hydra
    def download_one(attachment:, path_in_download_dir:, http_client:)
      path = Pathname.new(path_in_download_dir)
      attachment_path = destination.join(path.dirname, sanitize_filename(path.basename.to_s))

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
          handle_response_error(response, attachment:, attachment_path:, path_in_download_dir:)
        end
      end
    end

    def request_in_chunks(request, attachment:, attachment_path:, path_in_download_dir:)
      downloaded_file = attachment_path.open(mode: 'wb')

      request.on_body do |chunk|
        downloaded_file.write(chunk)
      end

      request.on_complete do |response|
        downloaded_file.close

        if !response.success?
          handle_response_error(response, attachment:, attachment_path:, path_in_download_dir:)
        end
      end
    end

    def handle_response_error(response, attachment:, attachment_path:, path_in_download_dir:)
      attachment_path.delete if attachment_path.exist? # -> case of retries failed, must cleanup partialy downloaded file
      on_error.call(attachment, path_in_download_dir, response.code)
    end
  end
end
