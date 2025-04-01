# frozen_string_literal: true

if ENV.fetch("FRANCE_CONNECT_ENABLED", "enabled") == "enabled"
  discover = OpenIDConnect::Discovery::Provider::Config.discover!("#{ENV.fetch('FC_PARTICULIER_BASE_URL')}/api/v2")

  protocol = Rails.env.production? ? 'https' : 'http'
  redirect_uri = "#{protocol}://#{ENV['APP_HOST']}/france_connect/particulier/callback"

  FRANCE_CONNECT = discover.as_json.merge(
    client_id: ENV.fetch('FC_PARTICULIER_ID'),
    identifier: ENV.fetch('FC_PARTICULIER_ID'),
    jwks: discover.jwks,
    redirect_uri:,
    secret: ENV.fetch('FC_PARTICULIER_SECRET')
  )
end
