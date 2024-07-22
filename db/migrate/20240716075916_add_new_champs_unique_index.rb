class AddNewChampsUniqueIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :champs, [:dossier_id, :stream, :stable_id, :row_id], unique: true, algorithm: :concurrently
  end
end
