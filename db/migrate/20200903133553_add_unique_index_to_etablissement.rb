class AddUniqueIndexToEtablissement < ActiveRecord::Migration[6.0]
  def change
    remove_index :etablissements, :dossier_id
    add_index :etablissements, :dossier_id, unique: true
  end
end
