# frozen_string_literal: true

if ENV.key?('SENDINBLUE_BALANCING_VALUE')
  require 'sib-api-v3-sdk'

  ActiveSupport.on_load(:action_mailer) do
    module Sendinblue
      class SMTP < ::Mail::SMTP; end
    end

    ActionMailer::Base.add_delivery_method :sendinblue, Sendinblue::SMTP
    ActionMailer::Base.sendinblue_settings = {
      user_name: ENV.fetch("SENDINBLUE_USER_NAME"),
      password: ENV.fetch("SENDINBLUE_SMTP_KEY"),
      address: ENV.fetch("SENDINBLUE_SMTP_ADDRESS", "smtp-relay.brevo.com"),
      domain: 'smtp-relay.brevo.com',
      port: ENV.fetch("SENDINBLUE_SMTP_PORT", "587"),
      authentication: :cram_md5
    }
  end

  SibApiV3Sdk.configure do |config|
    config.api_key['api-key'] = ENV["SENDINBLUE_API_V3_KEY"]
  end
end
