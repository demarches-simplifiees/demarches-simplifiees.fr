# frozen_string_literal: true

module Maintenance
  class BackfillInvalidDossiersForTiersTask < MaintenanceTasks::Task
    # Corrige les dossiers declarés pour un tiers mais sans avoir renseigné les infos du tiers
    # 2024-05-22-01
    def collection
      Dossier.where(for_tiers: true).where(mandataire_first_name: nil)
    end

    def process(element)
      element.update_column(:for_tiers, false)
    end
  end
end
