class AddMigratedToActiveStorageBlobs < ActiveRecord::Migration[6.1]
  def change
    add_column :active_storage_blobs, :prefixed_key, :boolean
  end
end
