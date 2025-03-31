# frozen_string_literal: true

class FranceConnectService
  def self.enabled?
    ENV.fetch("FRANCE_CONNECT_ENABLED", "enabled") == "enabled"
  end

  def self.authorization_uri
    client = FranceConnectParticulierClient.new

    state = SecureRandom.alphanumeric(32)
    nonce = SecureRandom.alphanumeric(32)

    uri = client.authorization_uri(
      scope: [:profile, :email],
      state:,
      nonce:,
      acr_values: 'eidas1'
    )

    [uri, state, nonce]
  end

  def self.find_or_retrieve_france_connect_information(code, nonce)
    fetched_fci, id_token = FranceConnectService.retrieve_user_informations_particulier(code, nonce)
    fci_to_return = FranceConnectInformation.find_by(france_connect_particulier_id: fetched_fci[:france_connect_particulier_id]) || fetched_fci
    [fci_to_return, id_token]
  end

  def self.logout_url(id_token:, host_with_port:, state:)
    post_logout_redirect_uri = Rails.application.routes.url_helpers.root_url(host: host_with_port)
    h = { id_token_hint: id_token, post_logout_redirect_uri:, state: }
    "#{FRANCE_CONNECT[:particulier][:logout_endpoint]}?#{h.to_query}"
  end

  private

  def self.retrieve_user_informations_particulier(code, nonce)
    client = FranceConnectParticulierClient.new(code)

    access_token = client.access_token!(client_auth_method: :secret)

    id_token = OpenIDConnect::ResponseObject::IdToken.decode(access_token.id_token, FRANCE_CONNECT[:particulier][:jwks])

    id_token.verify!(issuer: FRANCE_CONNECT[:particulier][:issuer], nonce:, client_id: FRANCE_CONNECT[:particulier][:identifier])

    user_info = access_token.userinfo!.raw_attributes

    fci = FranceConnectInformation.new(
      gender: user_info[:gender],
      given_name: user_info[:given_name],
      family_name: user_info[:family_name],
      email_france_connect: user_info[:email],
      birthdate: user_info[:birthdate],
      birthplace: user_info[:birthplace],
      france_connect_particulier_id: user_info[:sub]
    )

    [fci, access_token.id_token]
  end
end
