class FranceConnectService
  def initialize(code: nil, identifier: nil, secret: nil)
    @code = code
    @identifier = identifier
    @secret = secret
  end

  def self.enabled?
    Flipper.enabled?(:france_connect)
  end

  def authorization_uri
    client.authorization_uri(
      scope: Rails.configuration.x.fcp.scopes,
      state: SecureRandom.hex(16),
      nonce: SecureRandom.hex(16),
      acr_values: Rails.configuration.x.fcp.acr_values
    )
  end

  def find_or_retrieve_france_connect_information
    fetched_fci = fetch_france_connect_information!
    fci_identifier = fetched_fci[:france_connect_particulier_id]

    FranceConnectInformation.find_by(france_connect_particulier_id: fci_identifier) || fetched_fci
  end

  private

  attr_reader :code, :identifier, :secret

  def credentials
    return nil if identifier.nil? && secret.nil?

    { identifier: identifier, secret: secret }
  end

  def client
    @client ||= FranceConnectParticulierClient.new(code, credentials)
  end

  def retrieve_token!
    client.access_token!(
      client_auth_method: :secret,
      grant_type: :authorization_code,
      redirect_uri: Rails.configuration.x.fcp.redirect_uri,
      code: code
    )
  end

  def retrieve_user_information!
    retrieve_token!.userinfo!
  end

  def fetch_france_connect_information!
    raw = retrieve_user_information!.raw_attributes

    FranceConnectInformation.new(
      gender: raw[:gender],
      given_name: raw[:given_name],
      family_name: raw[:family_name],
      email_france_connect: raw[:email],
      birthdate: raw[:birthdate],
      birthplace: raw[:birthplace],
      france_connect_particulier_id: raw[:sub]
    )
  end
end
