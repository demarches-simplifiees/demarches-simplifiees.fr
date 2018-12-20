class DropOldCarto < ActiveRecord::Migration[5.2]
  def change
    drop_table :cadastres
    drop_table :quartier_prioritaires
  end
end
