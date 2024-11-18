# frozen_string_literal: true

class AutoArchiveProcedureDossiersJob < ApplicationJob
  def perform(procedure)
    procedure
      .dossiers
      .state_en_construction
      .find_each do |d|
        begin
          d.passer_automatiquement_en_instruction!
        rescue StandardError => e
          Sentry.capture_exception(e, extra: { procedure_id: procedure.id })
        end
      end
  end
end
