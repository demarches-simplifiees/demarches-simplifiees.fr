# frozen_string_literal: true

module Maintenance
  class T20241127MigrateChampExpressionReguliereToFormattedTask < MaintenanceTasks::Task
    # Documentation: les champs ExpressionReguliere sont migrés au nouveau champ Formatted
    # en mode avancé.
    # Voir aussi la maintenance task de transformation des types de champs.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    run_on_first_deploy

    def collection
      with_statement_timeout("5min") do
        Champ.where(type: ["Champs::ExpressionReguliereChamp", "Champs::FormattedChamp"]).in_batches
      end
    end

    def process(batch)
      batch.update_all(type: "Champs::FormattedChamp")
    end
  end
end