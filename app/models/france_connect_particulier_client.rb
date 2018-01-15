class FranceConnectParticulierClient < OpenIDConnect::Client
  def initialize(code = nil)
    super(
      identifier: FRANCE_CONNECT.particulier.identifier,
      secret: FRANCE_CONNECT.particulier.secret,
      redirect_uri: FRANCE_CONNECT.particulier.redirect_uri,
      authorization_endpoint: FRANCE_CONNECT.particulier.authorization_endpoint,
      token_endpoint: FRANCE_CONNECT.particulier.token_endpoint,
      userinfo_endpoint: FRANCE_CONNECT.particulier.userinfo_endpoint,
      logout_endpoint: FRANCE_CONNECT.particulier.logout_endpoint
    )

    if code.present?
      self.authorization_code = code
    end
  end
end
