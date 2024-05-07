class AddColumnForTiersEnabledToProcedure < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :for_tiers_enabled, :boolean, default: true, null: false
  end
end
