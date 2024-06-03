# frozen_string_literal: true

module Maintenance
  class BackfillDeposeAtOnDeletedDossiersTask < MaintenanceTasks::Task
    def collection
      DeletedDossier.where(depose_at: nil)
    end

    def process(element)
      element.update_column(:depose_at, element.deleted_at)
    end
  end
end
