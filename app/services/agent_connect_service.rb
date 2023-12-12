class AgentConnectService
  include OpenIDConnect

  def self.enabled?
    ENV.fetch("AGENT_CONNECT_ENABLED", "enabled") == "enabled"
  end

  def self.authorization_uri
    client = AgentConnectClient.new

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
    client = AgentConnectClient.new(code)

    access_token = client.access_token!(client_auth_method: :secret)

    discover = find_discover
    id_token = ResponseObject::IdToken.decode(access_token.id_token, discover.jwks)

    id_token.verify!(
      client_id: Rails.application.secrets.agent_connect[:identifier],
      issuer: discover.issuer,
      nonce: nonce
    )

    access_token
      .userinfo!
      .raw_attributes
  end

  private

  def self.find_discover
    Discovery::Provider::Config.discover!("#{ENV.fetch('AGENT_CONNECT_BASE_URL')}/api/v2")
  end
end
