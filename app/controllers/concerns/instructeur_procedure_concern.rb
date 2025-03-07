# frozen_string_literal: true

module InstructeurProcedureConcern
  extend ActiveSupport::Concern

  included do
    private

    def find_or_create_instructeur_procedure(procedure)
      InstructeursProcedure
        .create_with(last_revision_seen_id: procedure.published_revision_id)
        .find_or_create_by(instructeur: current_instructeur, procedure: procedure)
    end
  end
end
