# frozen_string_literal: true

module Maintenance
  class T20251017SetDefaultFiltersForAllProcedurePresentationsTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données pour…

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    # run_on_first_deploy

    def collection
      ProcedurePresentation.all
    end

    def process(element)
      element.set_default_filters
      element.save!
    rescue ActiveRecord::RecordNotFound
      # a column can be not found for various reasons (deleted tdc, changed type, etc)
      # in this case we just ignore the error and continue
    end
  end
end
