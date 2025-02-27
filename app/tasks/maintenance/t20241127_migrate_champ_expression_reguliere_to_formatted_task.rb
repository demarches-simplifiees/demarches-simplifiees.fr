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

    BATCH_SIZE = 100_000

    def collection
      rows_count = with_statement_timeout("5min") { Champ.where(type: "Champs::ExpressionReguliereChamp").count }
      ((rows_count / BATCH_SIZE) + 1).times.to_a
    end

    def process(_)
      champ_ids = with_statement_timeout("5min") { Champ.where(type: "Champs::ExpressionReguliereChamp").limit(BATCH_SIZE).ids }
      with_statement_timeout("5min") { Champ.where(id: champ_ids).update_all(type: "Champs::FormattedChamp") }
    end

    def count = nil
  end
end
