class AddStableIdToTypesDeChamp < ActiveRecord::Migration[5.2]
  def change
    add_column :types_de_champ, :stable_id, :bigint
    add_index :types_de_champ, :stable_id
  end
end
