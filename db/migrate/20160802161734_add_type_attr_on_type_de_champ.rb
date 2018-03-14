class AddTypeAttrOnTypeDeChamp < ActiveRecord::Migration[5.2]
  def change
    add_column :types_de_champ, :type, :string
  end
end
