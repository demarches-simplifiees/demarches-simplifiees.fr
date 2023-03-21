module DownloadManager
  class ParallelDownloadQueue
    DOWNLOAD_MAX_PARALLEL = ENV.fetch('DOWNLOAD_MAX_PARALLEL') { 10 }

    attr_accessor :attachments,
                  :destination,
                  :on_error

    def initialize(attachments, destination)
      @attachments = attachments
      @destination = destination
    end

    def download_all
      hydra = Typhoeus::Hydra.new(max_concurrency: DOWNLOAD_MAX_PARALLEL)

      attachments.map do |attachment, path|
        begin
          download_one(attachment: attachment,
                       path_in_download_dir: path,
                       http_client: hydra)
        rescue => e
          on_error.call(attachment, path, e)
        end
      end
      hydra.run
    end

    # can't be used with typhoeus, otherwise block is closed before the request is run by hydra
    def download_one(attachment:, path_in_download_dir:, http_client:)
      attachment_path = File.join(destination, path_in_download_dir)
      attachment_dir = File.dirname(attachment_path)

      FileUtils.mkdir_p(attachment_dir) if !Dir.exist?(attachment_dir) # defensive, do not write in undefined dir
      if attachment.is_a?(ActiveStorage::FakeAttachment)
        File.write(attachment_path, attachment.file.read, mode: 'wb')
      else
        request = Typhoeus::Request.new(attachment.url)
        request.on_complete do |response|
          if response.success?
            File.open(attachment_path, mode: "wb") do |fd|
              fd.write(response.body)
            end
          else
            File.delete(attachment_path) if File.exist?(attachment_path) # -> case of retries failed, must cleanup partialy downloaded file
            on_error.call(attachment, path_in_download_dir, response.code)
          end
        end
        http_client.queue(request)
      end
    end
  end
end
