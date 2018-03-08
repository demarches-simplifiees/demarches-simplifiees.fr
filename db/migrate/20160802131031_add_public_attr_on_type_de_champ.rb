class AddPublicAttrOnTypeDeChamp < ActiveRecord::Migration[5.2]
  def change
    add_column :types_de_champ, :private, :boolean, default: false
  end
end
