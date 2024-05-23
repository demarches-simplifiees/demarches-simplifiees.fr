# frozen_string_literal: true

module Maintenance
  class FixOpenProceduresWithClosingReasonTask < MaintenanceTasks::Task
    def collection
      Procedure
        .with_discarded
        .where
        .not(aasm_state: [:close, :depubliee])
        .where
        .not(closing_reason: nil)
    end

    def process(procedure)
      procedure.update!(closing_reason: nil)
    end
  end
end
