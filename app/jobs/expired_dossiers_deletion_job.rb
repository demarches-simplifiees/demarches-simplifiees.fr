class ExpiredDossiersDeletionJob < CronJob
  self.schedule_expression = "every day at 7 am"

  def perform(*args)
    ExpiredDossiersDeletionService.process_expired_dossiers_brouillon
  end
end
