# frozen_string_literal: true

class FixActiveStorageAttachmentMissingFkOnBlobId < ActiveRecord::Migration[6.1]
  def change
    if !foreign_key_exists?(:active_storage_attachments, :active_storage_blobs, column: :blob_id)
      add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id, validate: false
    end
  end
end
