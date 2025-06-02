# frozen_string_literal: true

if ENV.fetch('MAILCATCHER_ENABLED') == 'enabled'
  ActiveSupport.on_load(:action_mailer) do
    module Mailcatcher
      class SMTP < ::Mail::SMTP; end
    end

    ActionMailer::Base.add_delivery_method :mailcatcher, Mailcatcher::SMTP
    ActionMailer::Base.mailcatcher_settings = {
      address: ENV.fetch("MAILCATCHER_HOST"),
      port: ENV.fetch("MAILCATCHER_PORT")
    }
  end
end
