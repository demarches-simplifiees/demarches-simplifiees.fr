# frozen_string_literal: true

class Cron::AutoArchiveProcedureJob < Cron::CronJob
  self.schedule_expression = "every 1 minute"

  def perform(*args)
    procedures_to_close.each do |procedure|
      # A buggy procedure should NEVER prevent the closing of another procedure
      # we therefore exceptionally add a `begin resue` block.
      begin
        procedure
          .dossiers
          .state_en_construction
          .find_each(&:passer_automatiquement_en_instruction!)

        procedure.close!
      rescue StandardError => e
        Sentry.capture_exception(e, extra: { procedure_id: procedure.id })
      end
    end
  end

  def procedures_to_close
    Procedure
      .publiees
      .where("auto_archive_on <= ?", Time.zone.today)
  end
end
