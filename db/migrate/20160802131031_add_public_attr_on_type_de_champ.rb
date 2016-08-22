class AddPublicAttrOnTypeDeChamp < ActiveRecord::Migration
  def change
    add_column :types_de_champ, :private, :boolean, default: false
  end
end
