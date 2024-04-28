# frozen_string_literal: true

if ENV.fetch('MAILTRAP_ENABLED') == 'enabled'
  ActiveSupport.on_load(:action_mailer) do
    module Mailtrap
      class SMTP < ::Mail::SMTP; end
    end

    ActionMailer::Base.add_delivery_method :mailtrap, Mailtrap::SMTP
    ActionMailer::Base.mailtrap_settings = {
      user_name: Rails.application.secrets.mailtrap[:username],
      password: Rails.application.secrets.mailtrap[:password],
      address: 'sandbox.smtp.mailtrap.io',
      domain: 'sandbox.smtp.mailtrap.io',
      port: '2525',
      authentication: :login
    }
  end
end
