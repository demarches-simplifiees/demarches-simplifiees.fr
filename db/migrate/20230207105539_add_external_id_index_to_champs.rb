class AddExternalIdIndexToChamps < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :champs, :external_id, algorithm: :concurrently
  end
end
