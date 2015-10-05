class FcController < ApplicationController
  def index

    client = OpenIDConnect::Client.new(
      identifier: FRANCE_CONNECT.identifier,
      secret: FRANCE_CONNECT.secret,
      redirect_uri: 'http://localhost:3000',
      authorization_endpoint: 'https://fce.integ01.dev-franceconnect.fr/api/v1/authorize',
      token_endpoint: 'https://fce.integ01.dev-franceconnect.fr/api/v1/token',
      userinfo_endpoint: 'https://fce.integ01.dev-franceconnect.fr/api/v1/userinfo'
      )

    session[:state] = SecureRandom.hex(16)
    session[:nonce] = SecureRandom.hex(16)
    authorization_uri = client.authorization_uri(
      state: session[:state],
      nonce: session[:nonce]
    )
    redirect_to authorization_uri

  end
end