class AgentConnectService
  include OpenIDConnect

  def self.enabled?
    ENV.fetch("AGENT_CONNECT_ENABLED", "enabled") == "enabled"
  end

  def self.authorization_uri
    client = OpenIDConnect::Client.new(AGENT_CONNECT)

    state = SecureRandom.hex(16)
    nonce = SecureRandom.hex(16)

    uri = client.authorization_uri(
      scope: [:openid, :email, :given_name, :usual_name, :organizational_unit, :belonging_population, :siret],
      state:,
      nonce:,
      acr_values: 'eidas1'
    )

    [uri, state, nonce]
  end

  def self.user_info(code, nonce)
    client = OpenIDConnect::Client.new(AGENT_CONNECT)
    client.authorization_code = code

    access_token = client.access_token!(client_auth_method: :secret)

    id_token = ResponseObject::IdToken.decode(access_token.id_token, AGENT_CONNECT[:jwks])
    id_token.verify!(AGENT_CONNECT.merge(nonce: nonce))

    [access_token.userinfo!.raw_attributes, access_token.id_token]
  end
end
