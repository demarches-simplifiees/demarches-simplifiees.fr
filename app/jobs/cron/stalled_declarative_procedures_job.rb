# frozen_string_literal: true

class Cron::StalledDeclarativeProceduresJob < Cron::CronJob
  self.schedule_expression = "every 10 minutes"

  def perform
    Procedure.declarative.find_each do |procedure|
      procedure.dossiers.state_en_construction.where(declarative_triggered_at: nil).find_each do |dossier|
        ProcessStalledDeclarativeDossierJob.perform_later(dossier)
      end
    end
  end
end
