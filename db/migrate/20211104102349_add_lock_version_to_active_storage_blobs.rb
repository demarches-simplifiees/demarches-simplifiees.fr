# frozen_string_literal: true

class AddLockVersionToActiveStorageBlobs < ActiveRecord::Migration[6.1]
  def change
    add_column :active_storage_blobs, :lock_version, :integer
  end
end
