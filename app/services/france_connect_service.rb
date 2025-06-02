# frozen_string_literal: true

class FranceConnectService
  def self.enabled?
    ENV.fetch("FRANCE_CONNECT_ENABLED", "enabled") == "enabled"
  end

  def self.authorization_uri
    client = FranceConnectParticulierClient.new

    client.authorization_uri(
      scope: [:profile, :email],
      state: SecureRandom.hex(16),
      nonce: SecureRandom.hex(16),
      acr_values: 'eidas1'
    )
  end

  def self.find_or_retrieve_france_connect_information(code)
    fetched_fci = FranceConnectService.retrieve_user_informations_particulier(code)
    FranceConnectInformation.find_by(france_connect_particulier_id: fetched_fci[:france_connect_particulier_id]) || fetched_fci
  end

  private

  def self.retrieve_user_informations_particulier(code)
    client = FranceConnectParticulierClient.new(code)

    user_info = client.access_token!(client_auth_method: :secret)
      .userinfo!
      .raw_attributes

    FranceConnectInformation.new(
      gender: user_info[:gender],
      given_name: user_info[:given_name],
      family_name: user_info[:family_name],
      email_france_connect: user_info[:email],
      birthdate: user_info[:birthdate],
      birthplace: user_info[:birthplace],
      france_connect_particulier_id: user_info[:sub]
    )
  end
end
