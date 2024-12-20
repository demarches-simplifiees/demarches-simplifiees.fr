# frozen_string_literal: true

class Cron::EmptyDossiersBrouillonDeletionJob < Cron::CronJob
  self.schedule_expression = Expired.schedule_at(self)

  def self.deletion_window
    3.weeks.ago..2.weeks.ago
  end

  def perform(*args)
    Expired::DossiersDeletionService.new.process_empty_dossiers_brouillon(deletion_window)
  end
end
