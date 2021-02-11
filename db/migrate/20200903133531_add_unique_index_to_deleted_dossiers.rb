class AddUniqueIndexToDeletedDossiers < ActiveRecord::Migration[6.0]
  def change
    add_index :deleted_dossiers, [:dossier_id], unique: true
  end
end
