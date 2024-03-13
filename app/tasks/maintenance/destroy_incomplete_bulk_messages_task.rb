# frozen_string_literal: true

module Maintenance
  class DestroyIncompleteBulkMessagesTask < MaintenanceTasks::Task
    def collection
      BulkMessage.where(procedure: nil).where.missing(:groupe_instructeurs)
    end

    def process(element)
      element.destroy
    end
  end
end
