# frozen_string_literal: true

module Maintenance
  class MigrateExistingProcedurePathsTask < MaintenanceTasks::Task
    def collection
      Procedure.all
    end

    def process(element)
      element.save!

      if element.publiee?
        element.procedure_paths << ProcedurePath.find_or_create_by(path: element[:path])
      else
        if !Procedure.publiees.exists?(path: element[:path]) # the path is not used by another published procedure
          element.procedure_paths << ProcedurePath.find_or_create_by(path: element[:path])
        end
      end
      element.save!
    end
  end
end
