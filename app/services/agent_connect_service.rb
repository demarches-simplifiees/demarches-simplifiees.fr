class AgentConnectService
  def self.enabled?
    ENV.fetch("AGENT_CONNECT_ENABLED", "enabled") == "enabled"
  end

  def self.authorization_uri
    client = AgentConnectClient.new

    state = SecureRandom.hex(16)

    uri = client.authorization_uri(
      scope: [:openid, :email],
      state: state,
      nonce: SecureRandom.hex(16),
      acr_values: 'eidas1'
    )

    [uri, state]
  end

  def self.user_info(code)
    client = AgentConnectClient.new(code)

    client.access_token!(client_auth_method: :secret)
      .userinfo!
      .raw_attributes
  end
end
