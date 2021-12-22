require 'async'
require 'async/barrier'
require 'async/http/internet'

module DownloadManager
  class ParallelDownloadQueue
    include Utils::Retryable
    DOWNLOAD_MAX_PARALLEL = ENV.fetch('DOWNLOAD_MAX_PARALLEL') { 10 }

    attr_accessor :attachments,
                  :destination,
                  :on_error

    def initialize(attachments, destination)
      @attachments = attachments
      @destination = destination
    end

    def download_all
      Async do
        http_client = Async::HTTP::Internet.new
        barrier = Async::Barrier.new
        semaphore = Async::Semaphore.new(DOWNLOAD_MAX_PARALLEL, parent: barrier)

        attachments.map do |attachment, path|
          semaphore.async do
            begin
              with_retry(max_attempt: 1) do
                download_one(attachment: attachment,
                             path_in_download_dir: path,
                             http_client: http_client)
              end
            rescue => e
              on_error.call(attachment, path, e)
            end
          end
        end
        barrier.wait
      ensure
        http_client&.close
      end
    end

    def download_one(attachment:, path_in_download_dir:, http_client:)
      byte_written = 0
      attachment_path = File.join(destination, path_in_download_dir)
      attachment_dir = File.dirname(attachment_path)

      FileUtils.mkdir_p(attachment_dir) if !Dir.exist?(attachment_dir) # defensive, do not write in undefined dir
      if attachment.is_a?(PiecesJustificativesService::FakeAttachment)
        byte_written = File.write(attachment_path, attachment.file.read, mode: 'wb')
      else
        response = http_client.get(attachment.url)
        File.open(attachment_path, mode: 'wb') do |fd|
          response.body.each do |chunk|
            byte_written = byte_written + fd.write(chunk)
          end
          response.body.close
        end
      end
      byte_written
    rescue
      File.delete(attachment_path) if File.exist?(attachment_path) # -> case of retries failed, must cleanup partialy downloaded file
      raise
    end
  end
end
