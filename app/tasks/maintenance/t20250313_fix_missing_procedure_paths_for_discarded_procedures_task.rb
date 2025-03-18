# frozen_string_literal: true

module Maintenance
  class T20250313FixMissingProcedurePathsForDiscardedProceduresTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    run_on_first_deploy

    def collection
      Procedure.with_discarded.discarded.where.missing(:procedure_paths)
    end

    def process(element)
      element.ensure_path_exists
      element.save(validate: false)
    end
  end
end
