# frozen_string_literal: true

module Maintenance
  class BackfillChampsStableIdTask < MaintenanceTasks::Task
    def collection
      Dossier.select(:id)
    end

    def process(dossier)
      if Champ.exists?(dossier_id: dossier.id, stable_id: nil)
        day = 24 * 60 * 60 # 24 hours in seconds
        wait = rand(0...(day * 4)).seconds # every second over 4 days

        Migrations::BackfillStableIdJob
          .set(wait:)
          .perform_later(dossier.id)
      end
    end
  end
end
