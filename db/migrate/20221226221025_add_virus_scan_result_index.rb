# frozen_string_literal: true

class AddVirusScanResultIndex < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :active_storage_blobs, :virus_scan_result, algorithm: :concurrently
  end
end
