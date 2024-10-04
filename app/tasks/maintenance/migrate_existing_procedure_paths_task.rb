# frozen_string_literal: true

module Maintenance
  class MigrateExistingProcedurePathsTask < MaintenanceTasks::Task
    def collection
      Procedure.all
    end

    def process(element)
      if element.publiee?
        element.procedure_paths << ProcedurePath.find_or_create_by(path: element[:path])
      else
        if Procedure.publiees.exists?(path: element[:path]) # the path is already used by another published procedure
          element.procedure_paths << ProcedurePath.new(path: SecureRandom.uuid)
        else # the path is not used by another published procedure
          element.procedure_paths << ProcedurePath.find_or_create_by(path: element[:path])
        end
      end
      element.save!
    end
  end
end
