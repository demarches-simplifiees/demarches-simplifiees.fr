FRANCE_CONNECT = {
  particulier: {
    identifier: ENV['FC_PARTICULIER_ID'],
    secret: ENV['FC_PARTICULIER_SECRET'],
    redirect_uri: "https://#{ENV['APP_HOST']}/france_connect/particulier/callback",
    authorization_endpoint: "#{ENV['FC_PARTICULIER_BASE_URL']}/api/v1/authorize",
    token_endpoint: "#{ENV['FC_PARTICULIER_BASE_URL']}/api/v1/token",
    userinfo_endpoint: "#{ENV['FC_PARTICULIER_BASE_URL']}/api/v1/userinfo",
    logout_endpoint: "#{ENV['FC_PARTICULIER_BASE_URL']}/api/v1/logout"
  }
}
