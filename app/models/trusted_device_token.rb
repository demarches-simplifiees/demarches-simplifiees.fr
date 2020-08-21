# == Schema Information
#
# Table name: trusted_device_tokens
#
#  id             :bigint           not null, primary key
#  token          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  instructeur_id :bigint
#
class TrustedDeviceToken < ApplicationRecord
  LOGIN_TOKEN_VALIDITY = 1.week
  LOGIN_TOKEN_YOUTH = 15.minutes

  belongs_to :instructeur
  has_secure_token

  def token_valid?
    LOGIN_TOKEN_VALIDITY.ago < created_at
  end

  def token_young?
    LOGIN_TOKEN_YOUTH.ago < created_at
  end
end
