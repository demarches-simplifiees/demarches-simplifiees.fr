# frozen_string_literal: true

# This migration comes from active_storage (originally 20190112182829)
class AddServiceNameToActiveStorageBlobs < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    unless column_exists?(:active_storage_blobs, :service_name)
      add_column :active_storage_blobs, :service_name, :string
    end

    # rubocop:disable DS/Unscoped
    blobs_without_service_name = ActiveStorage::Blob.unscoped.where(service_name: nil)
    # rubocop:enable DS/Unscoped

    if (configured_service = ActiveStorage::Blob.service.name && blobs_without_service_name.count > 0)
      # Backfill the existing blobs with the service.
      # NB: during a continuous deployments, some blobs may still be created
      # with an empty service_name. A later migration will fix those later.

      say_with_time('backfill ActiveStorage::Blob.service.name. This could take a while…') do
        blobs_without_service_name.in_batches do |relation|
          relation.update_all service_name: configured_service
          sleep(0.01) # throttle
        end
      end
    end
  end

  def down
    remove_column :active_storage_blobs, :service_name
  end
end
