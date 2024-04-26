# frozen_string_literal: true

module Maintenance
  class FillChampsStableIdTask < MaintenanceTasks::Task
    def collection
      Champ.where(stable_id: nil).includes(:type_de_champ)
    end

    def process(champ)
      champ.update_columns(stable_id: champ.stable_id, stream: 'main')
    end

    def count
      sql = "SELECT reltuples FROM pg_class WHERE relname = 'champs';"
      Champ.connection.select_value(sql).to_i
    end
  end
end
