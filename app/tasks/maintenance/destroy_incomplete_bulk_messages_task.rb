# frozen_string_literal: true

module Maintenance
  class DestroyIncompleteBulkMessagesTask < MaintenanceTasks::Task
    def collection
      BulkMessage.all.filter { |bm| bm.procedure.nil? && bm.groupe_instructeurs.blank? }
    end

    def process(element)
      element.destroy
    end
  end
end
