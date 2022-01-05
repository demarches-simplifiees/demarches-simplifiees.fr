module DownloadManager
  class ProcedureAttachmentsExport
    delegate :destination, to: :@queue

    attr_reader :queue
    attr_accessor :errors

    def initialize(procedure, attachments, destination)
      @procedure = procedure
      @errors = {}
      @queue = ParallelDownloadQueue.new(attachments, destination)
      @queue.on_error = proc do |_attachment, path, error|
        errors[path] = true
        Rails.logger.error("Fail to download filename #{path} in procedure##{@procedure.id}, reason: #{error}")
      end
     end

    def download_all
      @queue.download_all
      write_report if !errors.empty?
    end

    private

    def write_report
      manifest_path = File.join(destination, 'LISEZMOI.txt')
      manifest_content = errors.map do |file_basename, _failed|
                                                      "Impossible de récupérer le fichier #{file_basename}"
                                                    end
        .join("\n")
      File.write(manifest_path, manifest_content)
    end
  end
end
