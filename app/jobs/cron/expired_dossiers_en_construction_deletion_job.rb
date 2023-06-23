class Cron::ExpiredDossiersEnConstructionDeletionJob < Cron::CronJob
  self.schedule_expression = "every day at 3 pm"

  def perform(*args)
    ExpiredDossiersDeletionService.process_expired_dossiers_en_construction
  end
end
