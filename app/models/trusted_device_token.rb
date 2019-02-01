class TrustedDeviceToken < ApplicationRecord
  belongs_to :gestionnaire
  has_secure_token
end
