# frozen_string_literal: true

class InitBlobServiceName < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    if column_exists?(:active_storage_blobs, :service_name)

      # rubocop:disable DS/Unscoped
      blobs_with_wrong_service_name = ActiveStorage::Blob.unscoped.where(service_name: 't')
      # rubocop:enable DS/Unscoped
      configured_service = ActiveStorage::Blob.service.name
      puts "Actual service: #{configured_service}"
      puts "blobs with wrong service name: #{blobs_with_wrong_service_name.count}"

      if (configured_service && blobs_with_wrong_service_name.count > 0)
        # Backfill the existing blobs with the service.
        say_with_time('backfill ActiveStorage::Blob.service.name. This could take a while…') do
          blobs_with_wrong_service_name.in_batches do |relation|
            relation.update_all service_name: configured_service
            sleep(0.01) # throttle
          end
        end
      end
      # rubocop:disable DS/Unscoped
      blobs_with_wrong_service_name = ActiveStorage::Blob.unscoped.where(service_name: 't')
      # rubocop:enable DS/Unscoped
      puts "Resulting blobs with wrong service name: #{blobs_with_wrong_service_name.count}"
    end
  end

  def down
  end
end
