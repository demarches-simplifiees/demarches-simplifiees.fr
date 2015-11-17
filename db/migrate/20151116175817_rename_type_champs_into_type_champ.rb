class RenameTypeChampsIntoTypeChamp < ActiveRecord::Migration
  def change
    rename_column :types_de_champ, :type_champs, :type_champ
  end
end
