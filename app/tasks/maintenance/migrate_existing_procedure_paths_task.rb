# frozen_string_literal: true

module Maintenance
  class MigrateExistingProcedurePathsTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    run_on_first_deploy

    def collection
      Procedure.all
    end

    def process(element)
      element.save!(validate: false)

      if element.publiee?
        element.procedure_paths << ProcedurePath.find_or_create_by(path: element[:path])
      else
        if !Procedure.publiees.exists?(path: element[:path]) # the path is not used by another published procedure
          element.procedure_paths << ProcedurePath.find_or_create_by(path: element[:path])
        end
      end
      element.save!(validate: false)
    end
  end
end
