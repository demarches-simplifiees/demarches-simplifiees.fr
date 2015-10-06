class FranceConnectClient < OpenIDConnect::Client

  def initialize params={}
    redirect_uri = 'http://localhost:3000/france_connect/callback'
    authorization_endpoint = 'https://fce.integ01.dev-franceconnect.fr/api/v1/authorize'
    token_endpoint = 'https://fce.integ01.dev-franceconnect.fr/api/v1/token'
    userinfo_endpoint = 'https://fce.integ01.dev-franceconnect.fr/api/v1/userinfo'

    super(
        identifier: FRANCE_CONNECT.identifier,
        secret: FRANCE_CONNECT.secret,
        redirect_uri: redirect_uri,
        authorization_endpoint: authorization_endpoint,
        token_endpoint: token_endpoint,
        userinfo_endpoint: userinfo_endpoint
    )
    self.authorization_code = params[:code] if params.has_key? :code
  end
end
