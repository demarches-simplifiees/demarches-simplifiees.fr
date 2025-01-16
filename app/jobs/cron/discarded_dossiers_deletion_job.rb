class Cron::DiscardedDossiersDeletionJob < Cron::CronJob
  self.schedule_expression = "every day at 02:00"

  def perform
    Dossier.purge_discarded
  end
end
