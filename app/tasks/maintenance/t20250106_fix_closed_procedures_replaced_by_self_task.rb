# frozen_string_literal: true

module Maintenance
  class T20250106FixClosedProceduresReplacedBySelfTask < MaintenanceTasks::Task
    # Fixes closed procedures that have replaced_by_procedure_id set to themselves (circular reference).
    # Sets closing_reason to 'other' and clears the replaced_by_procedure_id.
    def collection
      Procedure
        .with_discarded
        .closes
        .where('replaced_by_procedure_id = id')
    end

    def process(procedure)
      procedure.update!(
        closing_reason: Procedure.closing_reasons.fetch(:other),
        replaced_by_procedure_id: nil
      )
    end
  end
end
