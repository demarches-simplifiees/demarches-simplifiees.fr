# frozen_string_literal: true

module Maintenance
  class T20250526NullifyRowIdTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      Dossier.all
    end

    def process(dossier)
      dossier.champs.where(row_id: Champ::NULL_ROW_ID).update_all(row_id: nil)
    end

    def count
      with_statement_timeout("5min") do
        collection.count
      end
    end
  end
end
