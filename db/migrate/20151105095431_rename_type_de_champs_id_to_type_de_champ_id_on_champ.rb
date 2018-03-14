class RenameTypeDeChampsIdToTypeDeChampIdOnChamp < ActiveRecord::Migration[5.2]
  def change
    rename_column :champs, :type_de_champs_id, :type_de_champ_id
  end
end
