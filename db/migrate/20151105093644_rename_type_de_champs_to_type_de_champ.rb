class RenameTypeDeChampsToTypeDeChamp < ActiveRecord::Migration
  def change
    rename_table :types_de_champs, :types_de_champ
  end
end
