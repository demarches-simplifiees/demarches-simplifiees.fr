# frozen_string_literal: true

module Maintenance
  class MigrateExistingDiscardedProcedurePathsTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    run_on_first_deploy

    def collection
      Procedure.with_discarded.where.not(hidden_at: nil)
    end

    def process(element)
      Procedure.ignored_columns = []
      element.save!(validate: false)

      if element.publiee?
        element.procedure_paths << ProcedurePath.find_or_create_by(path: element.attributes["path"])
      else
        if !Procedure.publiees.exists?(path: element.attributes["path"]) # the path is not used by another published procedure
          element.procedure_paths << ProcedurePath.find_or_create_by(path: element.attributes["path"])
        end
      end
      element.save!(validate: false)
    end
  end
end
