# frozen_string_literal: true

module Maintenance
  class MigrateExistingProcedurePathsTask < MaintenanceTasks::Task
    def collection
      Procedure.all
    end

    def process(element)
      element.sync_procedure_path
      element.save!
    end
  end
end
