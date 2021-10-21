class Cron::DiscardedDossiersDeletionJob < Cron::CronJob
  self.schedule_expression = "every day at 2 am"

  def perform
    Dossier.purge_discarded
  end
end
