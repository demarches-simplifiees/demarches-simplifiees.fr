# frozen_string_literal: true

if ENV['HELO_ENABLED'] == 'enabled'
  ActiveSupport.on_load(:action_mailer) do
    module Helo
      class SMTP < ::Mail::SMTP; end
    end

    ActionMailer::Base.add_delivery_method :helo, Helo::SMTP
    ActionMailer::Base.helo_settings = {
      user_name: 'demarches-simplifiees',
      password: '',
      address: '127.0.0.1',
      domain: '127.0.0.1',
      port: ENV.fetch('HELO_PORT', '2525'),
      authentication: :plain,
    }
  end
end
