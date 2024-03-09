class Cron::ExpiredPrefilledDossiersDeletionJob < Cron::CronJob
  self.schedule_expression = Expired.schedule_at(self)

  def perform
    Dossier.prefilled.state_brouillon.where(user_id: nil, updated_at: ..5.days.ago).destroy_all
  end
end
