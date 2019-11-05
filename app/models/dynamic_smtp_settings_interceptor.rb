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
