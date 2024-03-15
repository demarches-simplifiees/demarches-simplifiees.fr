# frozen_string_literal: true

module Maintenance
  class FillChampsStableIdTask < MaintenanceTasks::Task
    def collection
      Champ.includes(:type_de_champ)
    end

    def process(champ)
      champ.update_columns(stable_id: champ.stable_id, stream: 'main')
    end
  end
end
