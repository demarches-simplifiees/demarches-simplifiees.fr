# frozen_string_literal: true

module Maintenance
  class BackfillDeposeAtOnDeletedDossiersTask < MaintenanceTasks::Task
    # Améliore les stats à propos des dates de dépôts pour les dossiers supprimés
    # 2024-04-05-01 PR #10259
    def collection
      DeletedDossier.where(depose_at: nil)
    end

    def process(element)
      element.update_column(:depose_at, element.deleted_at)
    end
  end
end
