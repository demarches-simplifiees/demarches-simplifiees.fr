# frozen_string_literal: true

class AddNotNullServiceNameToActiveStorageBlobs < ActiveRecord::Migration[6.1]
  def up
    unless column_exists?(:active_storage_blobs, :service_name, null: false)
      if (configured_service = ActiveStorage::Blob.service.name)
        # First backfill the remaining data.
        # (It should be fast, because the previous migration already backfilled almost all of it.)
        say_with_time('fill missings ActiveStorage::Blob.service_name. This could take a while…') do
          # rubocop:disable DS/Unscoped
          ActiveStorage::Blob.unscoped.where(service_name: nil).update_all service_name: configured_service
          # rubocop:enable DS/Unscoped
        end
      end

      change_column :active_storage_blobs, :service_name, :string, null: false
    end
  end

  def down
    change_column :active_storage_blobs, :service_name, :string, null: true
  end
end
