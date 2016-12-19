class FranceConnectService
  def self.retrieve_user_informations_particulier code
    client = FranceConnectParticulierClient.new code: code

    access_token = client.access_token!(client_auth_method: :secret)
    user_info = access_token.userinfo!
    hash = Hashie::Mash.new user_info.raw_attributes

    hash.france_connect_particulier_id = hash.sub
    hash
  end
end
