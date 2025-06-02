# frozen_string_literal: true

class AddDeviseTwoFactorToAdministrations < ActiveRecord::Migration[6.0]
  def change
    add_column :administrations, :encrypted_otp_secret, :string
    add_column :administrations, :encrypted_otp_secret_iv, :string
    add_column :administrations, :encrypted_otp_secret_salt, :string
    add_column :administrations, :consumed_timestep, :integer
    add_column :administrations, :otp_required_for_login, :boolean
  end
end
