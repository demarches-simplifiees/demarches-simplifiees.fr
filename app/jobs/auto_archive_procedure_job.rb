class AutoArchiveProcedureJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    Rails.logger.info("AutoArchiveProcedureJob started at #{Time.now}")
    Procedure.publiees.where("auto_archive_on <= ?", Date.today).each do |procedure|
      procedure.dossiers.state_en_construction.each do |dossier|
        dossier.received!
      end

      procedure.archive
    end
    Rails.logger.info("AutoArchiveProcedureJob ended at #{Time.now}")
  end
end
