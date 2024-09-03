# frozen_string_literal: true

class ValidateForeignKeyBetweenAttachmentsAndBlobs < ActiveRecord::Migration[6.1]
  def up
    validate_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id
  end
end
