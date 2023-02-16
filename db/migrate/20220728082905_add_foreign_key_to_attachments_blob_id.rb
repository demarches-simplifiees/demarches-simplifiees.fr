class AddForeignKeyToAttachmentsBlobId < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id, validate: false
  end
end
