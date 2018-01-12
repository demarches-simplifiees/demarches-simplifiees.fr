class FranceConnectService
  def self.authorization_uri
    client = FranceConnectParticulierClient.new

    client.authorization_uri(scope: [:profile, :email], state: SecureRandom.hex(16), nonce: SecureRandom.hex(16))
  end

  def self.retrieve_user_informations_particulier(code)
    client = FranceConnectParticulierClient.new(code)

    access_token = client.access_token!(client_auth_method: :secret)

    user_info = access_token.userinfo!
    hash = Hashie::Mash.new(user_info.raw_attributes)

    {
      gender: hash[:gender],
      given_name: hash[:given_name],
      family_name: hash[:family_name],
      email_france_connect: hash[:email],
      birthdate: hash[:birthdate],
      birthplace: hash[:birthplace],
      france_connect_particulier_id: hash.sub
    }
  end
end
