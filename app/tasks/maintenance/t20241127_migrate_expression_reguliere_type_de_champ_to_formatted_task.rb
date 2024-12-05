# frozen_string_literal: true

module Maintenance
  class T20241127MigrateExpressionReguliereTypeDeChampToFormattedTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    run_on_first_deploy

    def collection
      TypeDeChamp.where(type_champ: 'expression_reguliere')
    end

    def process(type_de_champ)
      type_de_champ.type_champ = 'formatted'
      type_de_champ.options["formatted_mode"] = "advanced"
      type_de_champ.save
    end

    def count
      collection.count
    end
  end
end
