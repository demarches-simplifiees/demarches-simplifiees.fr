# frozen_string_literal: true

if ENV['FC_PARTICULIER_BASE_URL'].present?
  discover = OpenIDConnect::Discovery::Provider::Config.discover!("#{ENV.fetch('FC_PARTICULIER_BASE_URL')}/api/v2")

  FRANCE_CONNECT = {
    particulier: Rails.application.secrets.france_connect_particulier
  }

  FRANCE_CONNECT[:particulier][:jwks] = discover.jwks
  FRANCE_CONNECT[:particulier][:issuer] = discover.issuer
end
