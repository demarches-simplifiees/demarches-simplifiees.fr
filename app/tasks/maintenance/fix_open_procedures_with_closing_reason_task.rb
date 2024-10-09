# frozen_string_literal: true

module Maintenance
  class FixOpenProceduresWithClosingReasonTask < MaintenanceTasks::Task
    # Corrige des démarches avec un motif de fermerture alors qu’elles ont été publiées
    # 2024-05-27-01 PR #10181
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
