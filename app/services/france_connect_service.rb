class FranceConnectService
  def self.retrieve_user_informations code
    client = FranceConnectClient.new code: code

    access_token = client.access_token!(client_auth_method: :secret)
    access_token.userinfo!
  end
end
