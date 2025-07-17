# frozen_string_literal: true

module InstructeurProcedureConcern
  extend ActiveSupport::Concern

  included do
    private

    def ensure_instructeur_procedures_for(procedures)
      current_instructeur_procedures = current_instructeur.instructeurs_procedures.where(procedure_id: procedures.map(&:id))
      top_position = current_instructeur_procedures.map(&:position).max || 0
      missing_instructeur_procedures = procedures.sort_by(&:published_at).map(&:id).filter_map do |procedure_id|
        if !procedure_id.in?(current_instructeur_procedures.map(&:procedure_id))
          { instructeur_id: current_instructeur.id, procedure_id:, position: top_position += 1 }
        end
      end
      InstructeursProcedure.insert_all(missing_instructeur_procedures) if missing_instructeur_procedures.size.positive?
    end

    def find_or_create_instructeur_procedure(procedure)
      InstructeursProcedure
        .create_with(last_revision_seen_id: procedure.published_revision_id)
        .find_or_create_by(instructeur: current_instructeur, procedure: procedure)
    end
  end
end
