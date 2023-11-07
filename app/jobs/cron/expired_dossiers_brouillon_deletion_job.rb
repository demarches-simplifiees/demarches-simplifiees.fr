class Cron::ExpiredDossiersBrouillonDeletionJob < Cron::CronJob
  self.schedule_expression = "every day at 10 pm"

  def perform(*args)
    Expired::DossiersDeletionService.new.process_expired_dossiers_brouillon
  end
end
