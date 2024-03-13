# frozen_string_literal: true

module Maintenance
  class BackfillBulkMessagesWithProcedureIdTask < MaintenanceTasks::Task
    def collection
      BulkMessage.where(procedure: nil).where.missing(:groupe_instructeurs)
    end

    def process(element)
      element.update(procedure_id: element.groupe_instructeurs.first.procedure.id)
    end
  end
end
