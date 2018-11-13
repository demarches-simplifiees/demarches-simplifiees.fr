module TrustedDeviceConcern
  extend ActiveSupport::Concern

  TRUSTED_DEVICE_COOKIE_NAME = :trusted_device
  TRUSTED_DEVICE_PERIOD = 1.month

  def trust_device
    cookies.encrypted[TRUSTED_DEVICE_COOKIE_NAME] = {
      value: JSON.generate({ created_at: Time.zone.now }),
      expires: TRUSTED_DEVICE_PERIOD,
      httponly: true
    }
  end

  def trusted_device?
    trusted_device_cookie.present? &&
      Time.zone.now - TRUSTED_DEVICE_PERIOD < JSON.parse(trusted_device_cookie)['created_at']
  end

  private

  def trusted_device_cookie
    cookies.encrypted[TRUSTED_DEVICE_COOKIE_NAME]
  end
end
