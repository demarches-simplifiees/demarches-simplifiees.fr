# frozen_string_literal: true

module Maintenance
  class FillChampsStableIdTask < MaintenanceTasks::Task
    def collection
      Dossier.all
    end

    def process(dossier)
      dossier.champs
        .includes(:type_de_champ)
        .where(stable_id: nil)
        .each do |champ|
          champ.update_columns(stable_id: champ.stable_id, stream: 'main')
        end
    end
  end
end
