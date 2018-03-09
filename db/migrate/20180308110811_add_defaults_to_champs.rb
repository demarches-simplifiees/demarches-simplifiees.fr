class AddDefaultsToChamps < ActiveRecord::Migration[5.2]
  def change
    change_column :champs, :private, :boolean, default: false, null: false
    change_column :types_de_champ, :private, :boolean, default: false, null: false
  end
end
