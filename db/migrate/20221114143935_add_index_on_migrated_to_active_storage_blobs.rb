class AddIndexOnMigratedToActiveStorageBlobs < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers
  disable_ddl_transaction!
  def up
    add_concurrent_index :active_storage_blobs, [:prefixed_key]
  end
end
