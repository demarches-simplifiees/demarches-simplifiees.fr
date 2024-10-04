# frozen_string_literal: true

module Maintenance
  class MigrateExistingProcedurePathsTask < MaintenanceTasks::Task
    def collection
      Procedure.all
    end

    def process(element)
      element.update_procedure_path
    end
  end
end
