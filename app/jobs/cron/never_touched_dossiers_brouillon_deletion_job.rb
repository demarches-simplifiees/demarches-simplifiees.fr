# frozen_string_literal: true

class Cron::NeverTouchedDossiersBrouillonDeletionJob < Cron::CronJob
  self.schedule_expression = Expired.schedule_at(self)

  def perform(*args)
    Expired::DossiersDeletionService.new.process_never_touched_dossiers_brouillon
  end
end
