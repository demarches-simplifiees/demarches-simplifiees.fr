# frozen_string_literal: true

module Maintenance
  class FillChampsStableIdTask < MaintenanceTasks::Task
    def collection
      Champ.all
    end

    def process(champ)
      if !champ.attribute_present?(:stable_id)
        champ.update_columns(stable_id: champ.stable_id, stream: 'main')
      end
    end

    def count
      sql = "SELECT reltuples FROM pg_class WHERE relname = 'champs';"
      Champ.connection.select_value(sql).to_i
    end
  end
end
