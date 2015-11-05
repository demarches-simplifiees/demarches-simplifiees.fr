class RenameTypeDeChampsIdToTypeDeChampIdOnChamp < ActiveRecord::Migration
  def change
    rename_column :champs, :type_de_champs_id, :type_de_champ_id
  end
end
