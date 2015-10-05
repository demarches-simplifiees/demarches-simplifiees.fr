class TestOpenIdController < ApplicationController
  def show


    client = OpenIDConnect::Client.new(
    identifier: FRANCE_CONNECT.identifier,
    secret: FRANCE_CONNECT.secret,
    redirect_uri: 'http://localhost:3000',
    authorization_endpoint: 'https://fce.integ01.dev-franceconnect.fr/api/v1/authorize',
    token_endpoint: 'https://fce.integ01.dev-franceconnect.fr/api/v1/token',
    userinfo_endpoint: 'https://fce.integ01.dev-franceconnect.fr/api/v1/userinfo'
    )


  client.authorization_code = params[:code]
  begin
    access_token = client.access_token!(client_auth_method: :secret)

    id_token = OpenIDConnect::ResponseObject::IdToken.decode access_token.id_token, FRANCE_CONNECT.secret

    puts id_token
    userinfo = access_token.userinfo!
    puts userinfo
  rescue Exception => e

    puts e.message
  end


  end
end