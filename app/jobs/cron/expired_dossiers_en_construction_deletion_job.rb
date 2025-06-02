# frozen_string_literal: true

class Cron::ExpiredDossiersEnConstructionDeletionJob < Cron::CronJob
  self.schedule_expression = Expired.schedule_at(self)

  def perform(*args)
    Expired::DossiersDeletionService.new.process_expired_dossiers_en_construction
  end
end
