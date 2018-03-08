class RenameTypeDeChampsToTypeDeChamp < ActiveRecord::Migration[5.2]
  def change
    rename_table :types_de_champs, :types_de_champ
  end
end
