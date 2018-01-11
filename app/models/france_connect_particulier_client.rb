class FranceConnectParticulierClient < OpenIDConnect::Client
  def initialize(code=nil)
    super(
        identifier: FRANCE_CONNECT.particulier_identifier,
        secret: FRANCE_CONNECT.particulier_secret,

        redirect_uri: FRANCE_CONNECT.particulier_redirect_uri,

        authorization_endpoint: FRANCE_CONNECT.particulier_authorization_endpoint,
        token_endpoint: FRANCE_CONNECT.particulier_token_endpoint,
        userinfo_endpoint: FRANCE_CONNECT.particulier_userinfo_endpoint,
        logout_endpoint: FRANCE_CONNECT.particulier_logout_endpoint
    )

    if code.present?
      self.authorization_code = code
    end
  end
end
