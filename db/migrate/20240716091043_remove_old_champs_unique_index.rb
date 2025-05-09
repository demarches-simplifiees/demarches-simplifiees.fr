class RemoveOldChampsUniqueIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    remove_index :champs, [:type_de_champ_id, :dossier_id, :row_id], algorithm: :concurrently
  end
end
