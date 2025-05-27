# frozen_string_literal: true

module Maintenance
  class T20250526NullifyRowIdTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    no_collection

    def process
      with_statement_timeout("15min") do
        Champ.where(row_id: Champ::NULL_ROW_ID)
          .in_batches(of: 50_000)
          .update_all(row_id: nil)
      end
    end
  end
end
