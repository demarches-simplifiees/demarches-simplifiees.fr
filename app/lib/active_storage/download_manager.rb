require 'async'
require 'async/barrier'
require 'async/http/internet'

class ActiveStorage::DownloadManager
  include Utils::Retryable
  DOWNLOAD_MAX_PARALLEL = ENV.fetch('DOWNLOAD_MAX_PARALLEL') { 10 }

  attr_reader :download_to_dir, :errors

  def download_all(attachments:, on_failure:)
    Async do
      internet = Async::HTTP::Internet.new
      barrier = Async::Barrier.new
      semaphore = Async::Semaphore.new(DOWNLOAD_MAX_PARALLEL, parent: barrier)

      attachments.map do |attachment, path|
        semaphore.async do
          begin
            with_retry(max_attempt: 1) do
              download_one(attachment: attachment,
                           path_in_download_dir: path,
                           async_internet: internet)
            end
          rescue => e
            on_failure.call(attachment, path, e)
          end
        end
      end
      barrier.wait
      write_error_manifest if !errors.empty?
    ensure
      internet&.close
    end
  end

  # beware, must be re-entrant because retryable
  def download_one(attachment:, path_in_download_dir:, async_internet:)
    byte_written = 0
    attachment_path = File.join(download_to_dir, path_in_download_dir)
    attachment_dir = File.dirname(attachment_path)

    FileUtils.mkdir_p(attachment_dir) if !Dir.exist?(attachment_dir) # defensive, do not write in undefined dir
    if attachment.is_a?(PiecesJustificativesService::FakeAttachment)
      byte_written = File.write(attachment_path, attachment.file.read, mode: 'wb')
    else
      response = async_internet.get(attachment.url)
      File.open(attachment_path, mode: 'wb') do |fd|
        response.body.each do |chunk|
          byte_written = byte_written + fd.write(chunk)
        end
        response.body.close
      end
    end
    track_retryable_download_state(attachment_path: attachment_path, state: true) # -> fail once, success after -> no failure
    byte_written
  rescue
    track_retryable_download_state(attachment_path: attachment_path, state: false) #
    File.delete(attachment_path) if File.exist?(attachment_path) # -> case of retries failed, must cleanup partialy downloaded file
    raise
  end

  private

  def initialize(download_to_dir:)
    @download_to_dir = download_to_dir
    @errors = {}
  end

  def track_retryable_download_state(attachment_path:, state:)
    key = File.basename(attachment_path)
    if state
      errors.delete(key) # do not keep track of success, otherwise errors map grows
    else
      errors[key] = state
    end
  end

  def write_error_manifest
    manifest_path = File.join(download_to_dir, 'LISEZMOI.txt')
    manifest_content = errors.map do |file_basename, _failed|
                                                    "Impossible de récupérer le fichier #{file_basename}"
                                                  end
      .join("\n")
    File.write(manifest_path, manifest_content)
  end
end
