# frozen_string_literal: true

class AddOtpSecretToSuperAdmin < ActiveRecord::Migration[7.0]
  def change
    add_column :super_admins, :otp_secret, :string
  end
end
