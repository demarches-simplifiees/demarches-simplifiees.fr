class TrustedDeviceToken < ApplicationRecord
  LOGIN_TOKEN_VALIDITY = 1.week
  LOGIN_TOKEN_YOUTH = 15.minutes

  belongs_to :gestionnaire
  has_secure_token

  def token_valid?
    LOGIN_TOKEN_VALIDITY.ago < created_at
  end

  def token_young?
    LOGIN_TOKEN_YOUTH.ago < created_at
  end
end
