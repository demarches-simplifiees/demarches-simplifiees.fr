class TrustedDeviceToken < ApplicationRecord
  LOGIN_TOKEN_VALIDITY = 45.minutes

  belongs_to :gestionnaire
  has_secure_token

  def token_valid?
    LOGIN_TOKEN_VALIDITY.ago < created_at
  end
end
