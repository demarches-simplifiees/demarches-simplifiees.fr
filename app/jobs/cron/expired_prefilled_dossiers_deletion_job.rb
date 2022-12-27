class Cron::ExpiredPrefilledDossiersDeletionJob < Cron::CronJob
  self.schedule_expression = "every month at 3:00"

  def perform
    Dossier.prefilled.state_brouillon.where("updated_at < ?", 1.month.ago).destroy_all
  end
end
