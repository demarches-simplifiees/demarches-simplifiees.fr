# frozen_string_literal: true

module InstructeurProcedureConcern
  extend ActiveSupport::Concern

  included do
    private

    def ensure_instructeur_procedures_for(procedures)
      current_instructeur_procedures = current_instructeur.instructeurs_procedures.where(procedure_id: procedures.map(&:id))
      top_position = current_instructeur_procedures.map(&:position).max.to_i
      missing_instructeur_procedures = procedures.sort_by(&:published_at).filter_map do |procedure|
        if !procedure.id.in?(current_instructeur_procedures.map(&:procedure_id))
          { instructeur_id: current_instructeur.id, procedure_id: procedure.id, position: top_position += 1, last_revision_seen_id: procedure.published_revision_id }
        end
      end
      InstructeursProcedure.insert_all(missing_instructeur_procedures) if missing_instructeur_procedures.size.positive?
    end

    def find_or_create_instructeur_procedure(procedure)
      instructeur_procedure = InstructeursProcedure.find_or_initialize_by(
        instructeur: current_instructeur,
        procedure: procedure
      )

      if instructeur_procedure.new_record?
        instructeur_procedure.last_revision_seen_id = procedure.published_revision_id
        instructeur_procedure.position = current_instructeur.instructeurs_procedures.map(&:position).max.to_i + 1
        instructeur_procedure.save!
      end

      instructeur_procedure
    end
  end
end
