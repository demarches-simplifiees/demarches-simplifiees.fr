# == Schema Information
#
# Table name: administrations
#
#  id                        :integer          not null, primary key
#  consumed_timestep         :integer
#  current_sign_in_at        :datetime
#  current_sign_in_ip        :string
#  email                     :string           default(""), not null
#  encrypted_otp_secret      :string
#  encrypted_otp_secret_iv   :string
#  encrypted_otp_secret_salt :string
#  encrypted_password        :string           default(""), not null
#  failed_attempts           :integer          default(0), not null
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string
#  locked_at                 :datetime
#  otp_required_for_login    :boolean
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string
#  sign_in_count             :integer          default(0), not null
#  unlock_token              :string
#  created_at                :datetime
#  updated_at                :datetime
#
class Administration < ApplicationRecord
  devise :rememberable, :trackable, :validatable, :lockable, :async, :recoverable,
    :two_factor_authenticatable, :otp_secret_encryption_key => Rails.application.secrets.otp_secret_key

  def enable_otp!
    self.otp_secret = Administration.generate_otp_secret
    self.otp_required_for_login = true
    save!
  end

  def disable_otp!
    self.assign_attributes(
      {
        encrypted_otp_secret: nil,
        encrypted_otp_secret_iv: nil,
        encrypted_otp_secret_salt: nil,
        consumed_timestep: nil,
        otp_required_for_login: false
      }
    )
    save!
  end

  def invite_admin(email)
    user = User.create_or_promote_to_administrateur(email, SecureRandom.hex)

    if user.valid?
      user.invite_administrateur!(id)
    end

    user
  end
end
