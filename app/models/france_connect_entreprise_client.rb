class FranceConnectEntrepriseClient < OpenIDConnect::Client

  def initialize params={}
    super(
        identifier: FRANCE_CONNECT.identifier,
        secret: FRANCE_CONNECT.secret,

        redirect_uri: FRANCE_CONNECT.entreprise_redirect_uri,

        authorization_endpoint: FRANCE_CONNECT.entreprise_authorization_endpoint,
        token_endpoint: FRANCE_CONNECT.entreprise_token_endpoint,
        userinfo_endpoint: FRANCE_CONNECT.entreprise_userinfo_endpoint,
        logout_endpoint: FRANCE_CONNECT.entreprise_logout_endpoint
    )
    self.authorization_code = params[:code] if params.has_key? :code
  end
end
