class AddTypeAttrOnTypeDeChamp < ActiveRecord::Migration
  def change
    add_column :types_de_champ, :type, :string
  end
end
