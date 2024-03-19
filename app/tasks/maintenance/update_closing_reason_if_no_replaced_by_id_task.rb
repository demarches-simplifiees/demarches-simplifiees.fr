# frozen_string_literal: true

module Maintenance
  class UpdateClosingReasonIfNoReplacedByIdTask < MaintenanceTasks::Task
    def collection
      Procedure
        .with_discarded
        .closes
        .where(closing_reason: Procedure.closing_reasons.fetch(:internal_procedure))
        .where(replaced_by_procedure_id: nil)
    end

    def process(procedure)
      procedure.update!(closing_reason: Procedure.closing_reasons.fetch(:other))
    end
  end
end
