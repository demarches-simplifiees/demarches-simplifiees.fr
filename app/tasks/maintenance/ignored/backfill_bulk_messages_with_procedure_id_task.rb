# frozen_string_literal: true

module Maintenance::Ignored
  class BackfillBulkMessagesWithProcedureIdTask < MaintenanceTasks::Task
    def collection
      BulkMessage
        .where(procedure: nil)
        .includes(:groupe_instructeurs)
        .where
        .not(groupe_instructeurs: { id: nil })
    end

    def process(element)
      element.update(procedure_id: element.groupe_instructeurs.first.procedure.id)
    end
  end
end
