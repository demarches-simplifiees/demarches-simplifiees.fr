# Note: this class is instanciated when being added as an interceptor
# during the app initialization.
#
# If you edit this file in development env, you will need to restart
# the app to see the changes.

class DynamicSmtpSettingsInterceptor
  def self.delivering_email(message)
    if balance_to_sendinblue?
      ApplicationMailer.wrap_delivery_behavior(message, :sendinblue)
    end
    # fallback to the default delivery method
  end

  private

  def self.balance_to_sendinblue?
    if ENV.fetch('SENDINBLUE_ENABLED') != 'enabled'
      false
    elsif ENV.fetch('SENDINBLUE_BALANCING') == 'enabled'
      rand(0..99) < ENV.fetch('SENDINBLUE_BALANCING_VALUE').to_i
    else
      true
    end
  end
end
