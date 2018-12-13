class CreateChampGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :champ_groups do |t|
      t.bigint :parent_id, index: true
      t.integer :order_place, null: false

      t.timestamps
    end

    add_column :types_de_champ, :parent_id, :bigint
    add_index :types_de_champ, :parent_id

    add_column :champs, :group_id, :bigint
    add_index :champs, :group_id

    add_foreign_key :champ_groups, :champs, column: :parent_id
    add_foreign_key :types_de_champ, :types_de_champ, column: :parent_id
    add_foreign_key :champs, :champ_groups, column: :group_id
  end
end
