# Note: this class is instanciated when being added as an interceptor
# during the app initialization.
#
# If you edit this file in development env, you will need to restart
# the app to see the changes.

class DynamicSmtpSettingsInterceptor
  def self.delivering_email(message)
    if ENV['SENDINBLUE_BALANCING'] == 'enabled'
      if rand(0..99) < ENV['SENDINBLUE_BALANCING_VALUE'].to_i
        message.delivery_method.settings = {
          user_name: ENV['SENDINBLUE_USER_NAME'],
          password: ENV['SENDINBLUE_SMTP_KEY'],
          address: 'smtp-relay.sendinblue.com',
          domain: 'smtp-relay.sendinblue.com',
          port: '587',
          authentication: :cram_md5
        }
      end
    end
  end
end
