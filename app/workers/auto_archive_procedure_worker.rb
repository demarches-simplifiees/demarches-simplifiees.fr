class AutoArchiveProcedureWorker
  def perform(*args)
    Rails.logger.info("AutoArchiveProcedureWorker started at #{Time.now}")
    Procedure.publiees.where("auto_archive_on <= ?", Date.today).each do |procedure|
      procedure.dossiers.state_en_construction.each do |dossier|
        dossier.received!
      end

      procedure.archive
    end
    Rails.logger.info("AutoArchiveProcedureWorker ended at #{Time.now}")
  end

  def queue_name
    "cron"
  end

  handle_asynchronously :perform
end
