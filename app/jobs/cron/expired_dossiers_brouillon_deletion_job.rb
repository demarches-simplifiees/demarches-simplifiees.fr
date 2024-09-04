# frozen_string_literal: true

class Cron::ExpiredDossiersBrouillonDeletionJob < Cron::CronJob
  self.schedule_expression = Expired.schedule_at(self)

  def perform(*args)
    Expired::DossiersDeletionService.new.process_expired_dossiers_brouillon
  end
end
