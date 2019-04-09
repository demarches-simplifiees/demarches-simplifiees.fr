class RemoveTypeFromTypesDeChamp < ActiveRecord::Migration[5.2]
  def change
    remove_column :types_de_champ, :type, :string
  end
end
