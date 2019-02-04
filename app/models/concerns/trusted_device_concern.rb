module TrustedDeviceConcern
  extend ActiveSupport::Concern

  TRUSTED_DEVICE_COOKIE_NAME = :trusted_device
  TRUSTED_DEVICE_PERIOD = 1.month

  def trust_device(start_at)
    cookies.encrypted[TRUSTED_DEVICE_COOKIE_NAME] = {
      value: JSON.generate({ created_at: start_at }),
      expires: start_at + TRUSTED_DEVICE_PERIOD,
      httponly: true
    }
  end

  def trusted_device?
    trusted_device_cookie.present? &&
      (Time.zone.now - TRUSTED_DEVICE_PERIOD) < trusted_device_cookie_created_at
  end

  def send_login_token_or_bufferize(gestionnaire)
    if !gestionnaire.young_login_token?
      login_token = gestionnaire.login_token!
      GestionnaireMailer.send_login_token(gestionnaire, login_token).deliver_later
    end
  end

  private

  def trusted_device_cookie_created_at
    Time.zone.parse(JSON.parse(trusted_device_cookie)['created_at'])
  end

  def trusted_device_cookie
    cookies.encrypted[TRUSTED_DEVICE_COOKIE_NAME]
  end
end
