# frozen_string_literal: true

class AddOCRColumnToActiveStorageBlobs < ActiveRecord::Migration[7.1]
  def change
    add_column :active_storage_blobs, :ocr, :jsonb
  end
end
