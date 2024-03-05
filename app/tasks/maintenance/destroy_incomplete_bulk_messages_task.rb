# frozen_string_literal: true

module Maintenance
  class DestroyIncompleteBulkMessagesTask < MaintenanceTasks::Task
    def collection
      BulkMessage.select { |bm| bm.procedure.nil? && bm.groupe_instructeurs.blank? }
    end

    def process(element)
      element.destroy
    end

    def count
      collection.count
    end
  end
end
