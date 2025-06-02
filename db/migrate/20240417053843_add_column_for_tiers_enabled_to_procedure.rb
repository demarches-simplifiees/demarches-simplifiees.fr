# frozen_string_literal: true

class AddColumnForTiersEnabledToProcedure < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :procedures, :for_tiers_enabled, :boolean, default: true, null: false
    end
  end
end
