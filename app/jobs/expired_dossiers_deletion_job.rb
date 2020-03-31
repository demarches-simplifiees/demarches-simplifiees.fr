class ExpiredDossiersDeletionJob < CronJob
  self.cron_expression = "0 7 * * *"

  def perform(*args)
    ExpiredDossiersDeletionService.process_expired_dossiers_brouillon
  end
end
