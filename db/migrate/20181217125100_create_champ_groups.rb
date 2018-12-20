class CreateChampGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :types_de_champ, :parent_id, :bigint
    add_index :types_de_champ, :parent_id

    add_column :champs, :parent_id, :bigint
    add_index :champs, :parent_id

    add_column :champs, :row, :integer
    add_index :champs, :row

    add_foreign_key :types_de_champ, :types_de_champ, column: :parent_id
    add_foreign_key :champs, :champs, column: :parent_id
  end
end
