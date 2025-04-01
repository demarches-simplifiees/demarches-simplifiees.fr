# frozen_string_literal: true

if ENV.fetch("FRANCE_CONNECT_ENABLED", "enabled") == "enabled"
  discover = OpenIDConnect::Discovery::Provider::Config.discover!("#{ENV.fetch('FC_PARTICULIER_BASE_URL')}/api/v2")

  FRANCE_CONNECT = {}

  protocol = Rails.env.production? ? 'https' : 'http'

  FRANCE_CONNECT[:particulier] = {
    authorization_endpoint: discover.authorization_endpoint,
    identifier: ENV.fetch('FC_PARTICULIER_ID'),
    issuer: discover.issuer,
    jwks: discover.jwks,
    logout_endpoint: discover.end_session_endpoint,
    redirect_uri: "#{protocol}://#{ENV['APP_HOST']}/france_connect/particulier/callback",
    secret: ENV.fetch('FC_PARTICULIER_SECRET'),
    token_endpoint: discover.token_endpoint,
    userinfo_endpoint: discover.userinfo_endpoint
  }
end
