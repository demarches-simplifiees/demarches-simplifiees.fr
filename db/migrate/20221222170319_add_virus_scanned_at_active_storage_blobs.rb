# frozen_string_literal: true

class AddVirusScannedAtActiveStorageBlobs < ActiveRecord::Migration[6.1]
  def change
    add_column :active_storage_blobs, :virus_scan_result, :string
    add_column :active_storage_blobs, :virus_scanned_at, :datetime
  end
end
