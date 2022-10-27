module DownloadManager
  class ProcedureAttachmentsExport
    delegate :destination, to: :@queue

    attr_reader :queue
    attr_accessor :errors

    def initialize(procedure, attachments, destination)
      @procedure = procedure
      @errors = {}
      @queue = ParallelDownloadQueue.new(attachments, destination)
      @queue.on_error = proc do |attachment, path, error|
        errors[path] = [attachment, path]
        Rails.logger.error("Fail to download filename #{path} in procedure##{@procedure.id}, reason: #{error}")
      end
    end

    def download_all(attempt_left: 1)
      @queue.download_all
      if !errors.empty? && attempt_left.positive?
        retryable_queue = self.class.new(@procedure, errors.values, destination)
        retryable_queue.download_all(attempt_left: 0)
        retryable_queue.write_report if !retryable_queue.errors.empty?
      end
    end

    def write_report
      manifest_path = File.join(destination, '-LISTE-DES-FICHIERS-EN-ERREURS.txt')
      manifest_content = errors.map do |file_basename, _failed|
                                                      "Impossible de récupérer le fichier #{file_basename}"
                                                    end
        .join("\n")
      File.write(manifest_path, manifest_content)
    end
  end
end
