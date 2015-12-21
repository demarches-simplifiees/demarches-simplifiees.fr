class FranceConnectService
  def self.retrieve_user_informations_entreprise code
    client = FranceConnectEntrepriseClient.new code: code

    access_token = client.access_token!(client_auth_method: :secret)
    user_info = access_token.userinfo!
    Hashie::Mash.new user_info.raw_attributes
  end
end
