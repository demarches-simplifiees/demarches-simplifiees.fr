# frozen_string_literal: true

module Maintenance
  class BackfillBulkMessagesWithProcedureIdTask < MaintenanceTasks::Task
    def collection
      BulkMessage.select { |bm| bm.procedure.nil? && bm.groupe_instructeurs.present? }
    end

    def process(element)
      element.update(procedure_id: element.groupe_instructeurs.first.procedure.id
    end

    def count
      collection.count
    end
  end
end
