class Cron::ExpiredDossiersTermineDeletionJob < Cron::CronJob
  self.schedule_expression = "every day at 7 am"

  def perform(*args)
    # ExpiredDossiersDeletionService.new.process_expired_dossiers_termine
    return "until we purge stock"
  end
end
