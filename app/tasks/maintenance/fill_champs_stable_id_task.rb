# frozen_string_literal: true

module Maintenance
  class FillChampsStableIdTask < MaintenanceTasks::Task
    BATCH = 1_000

    def collection
      (Dossier.last.id / BATCH).ceil.times.to_a
    end

    def process(batch_number)
      dossier_id_start = batch_number * BATCH
      dossier_id_end = dossier_id_start + BATCH
      Champ
        .where(dossier_id: dossier_id_start..dossier_id_end, stable_id: nil)
        .joins(:type_de_champ)
        .select('champs.id, types_de_champ.stable_id as type_de_champ_stable_id')
        .find_each do |champ|
          champ.update_columns(stable_id: champ.type_de_champ_stable_id, stream: 'main')
        end
    end
  end
end
