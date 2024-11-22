# frozen_string_literal: true

module Maintenance
  class FixAvisExpertsProcedureMismatchTask < MaintenanceTasks::Task
    # Some avis have incorrect experts_procedure associations where the procedure_id
    # doesn't match the dossier's procedure_id. This task fixes those mismatches.

    def collection
      Avis
        .joins(:experts_procedure, dossier: :procedure)
        .where.not('experts_procedures.procedure_id = procedures.id')
    end

    def process(avis)
      expert = avis.expert
      correct_procedure = avis.dossier.procedure

      correct_experts_procedure = ExpertsProcedure.find_or_create_by(
        procedure: correct_procedure,
        expert: expert
      )

      avis.update!(experts_procedure: correct_experts_procedure)
    end
  end
end
