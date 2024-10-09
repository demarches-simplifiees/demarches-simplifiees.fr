# frozen_string_literal: true

module Maintenance
  class BackfillBulkMessagesWithProcedureIdTask < MaintenanceTasks::Task
    # Périmètre: envoi d’un email groupé aux usagers ayant dossiers en brouillon.
    # Change la manière dont ces messages sont liés aux démarches.
    # 2024-03-12-01 PR #10071
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
