# frozen_string_literal: true

if ENV.enabled?("MAILTRAP")
  ActiveSupport.on_load(:action_mailer) do
    module Mailtrap
      class SMTP < ::Mail::SMTP; end
    end

    ActionMailer::Base.add_delivery_method :mailtrap, Mailtrap::SMTP
    ActionMailer::Base.mailtrap_settings = {
      user_name: ENV.fetch("MAILTRAP_USERNAME"),
      password: ENV.fetch("MAILTRAP_PASSWORD"),
      address: 'sandbox.smtp.mailtrap.io',
      domain: 'sandbox.smtp.mailtrap.io',
      port: '2525',
      authentication: :login
    }
  end
end
