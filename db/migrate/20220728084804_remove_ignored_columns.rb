class RemoveIgnoredColumns < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      remove_column :commentaires, :user_id
      remove_column :dossiers, :en_construction_conservation_extension
      remove_column :types_de_champ, :migrated_parent
      remove_column :types_de_champ, :revision_id
      remove_column :types_de_champ, :parent_id
      remove_column :types_de_champ, :order_place
    end
  end
end
