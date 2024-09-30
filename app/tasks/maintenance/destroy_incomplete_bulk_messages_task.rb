# frozen_string_literal: true

module Maintenance
  class DestroyIncompleteBulkMessagesTask < MaintenanceTasks::Task
    # Périmètre: envoi d’un email groupé aux usagers ayant dossiers en brouillon.
    # Change la manière dont ces messages sont liés aux démarches.
    # Suite de BackfillBulkMessagesWithProcedureIdTask
    # 2024-03-12-01 PR #10071
    def collection
      BulkMessage.where(procedure: nil).where.missing(:groupe_instructeurs)
    end

    def process(element)
      element.destroy
    end
  end
end
