class AddPrivateToChampAndTypeDeChamp < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :champs, :private, :boolean, index: true
    add_column :types_de_champ, :private, :boolean, index: true

    add_index :champs, :private, algorithm: :concurrently
    add_index :types_de_champ, :private, algorithm: :concurrently
  end
end
