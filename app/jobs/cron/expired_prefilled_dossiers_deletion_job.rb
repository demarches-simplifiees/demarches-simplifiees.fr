class Cron::ExpiredPrefilledDossiersDeletionJob < Cron::CronJob
  self.schedule_expression = "every day at 3:00"

  def perform
    Dossier.prefilled.state_brouillon.where(user_id: nil, updated_at: ..5.days.ago).destroy_all
  end
end
