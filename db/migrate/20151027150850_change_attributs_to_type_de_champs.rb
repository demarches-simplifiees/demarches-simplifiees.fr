class ChangeAttributsToTypeDeChamps < ActiveRecord::Migration
  def change
    rename_column :types_de_champs, :type, :type_champs
    add_column :types_de_champs, :description, :text
  end
end
