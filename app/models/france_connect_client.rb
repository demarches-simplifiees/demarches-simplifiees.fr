class FranceConnectClient < OpenIDConnect::Client

  def initialize params={}
    super(
        identifier: FRANCE_CONNECT.identifier,
        secret: FRANCE_CONNECT.secret,

        redirect_uri: FRANCE_CONNECT.redirect_uri,

        authorization_endpoint: FRANCE_CONNECT.authorization_endpoint,
        token_endpoint: FRANCE_CONNECT.token_endpoint,
        userinfo_endpoint: FRANCE_CONNECT.userinfo_endpoint,
        logout_endpoint: FRANCE_CONNECT.logout_endpoint
    )
    self.authorization_code = params[:code] if params.has_key? :code
  end
end
