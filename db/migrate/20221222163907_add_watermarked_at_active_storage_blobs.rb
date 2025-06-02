# frozen_string_literal: true

class AddWatermarkedAtActiveStorageBlobs < ActiveRecord::Migration[6.1]
  def change
    add_column :active_storage_blobs, :watermarked_at, :datetime
  end
end
