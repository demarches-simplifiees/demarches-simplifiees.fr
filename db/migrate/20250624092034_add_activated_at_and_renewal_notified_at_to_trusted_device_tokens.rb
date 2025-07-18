# frozen_string_literal: true

class AddActivatedAtAndRenewalNotifiedAtToTrustedDeviceTokens < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :trusted_device_tokens, :activated_at, :datetime
    add_column :trusted_device_tokens, :renewal_notified_at, :datetime
    add_index :trusted_device_tokens, [:activated_at, :renewal_notified_at], algorithm: :concurrently
  end
end
