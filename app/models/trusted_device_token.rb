# frozen_string_literal: true

class TrustedDeviceToken < ApplicationRecord
  LOGIN_TOKEN_VALIDITY = 1.week
  LOGIN_TOKEN_YOUTH = 15.minutes

  belongs_to :instructeur, optional: false
  has_secure_token

  scope :expiring_in_one_week, -> {
    where(activated_at: (TrustedDeviceConcern::TRUSTED_DEVICE_PERIOD.ago)..((TrustedDeviceConcern::TRUSTED_DEVICE_PERIOD - 1.week).ago),
          renewal_notified_at: nil)
  }

  def token_valid?
    LOGIN_TOKEN_VALIDITY.ago < created_at
  end

  def token_young?
    LOGIN_TOKEN_YOUTH.ago < created_at
  end
end
