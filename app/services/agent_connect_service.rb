class AgentConnectService
  def self.enabled?
    ENV.fetch("AGENT_CONNECT_ENABLED", "enabled") == "enabled"
  end

  def self.authorization_uri
    client = AgentConnectClient.new

    client.authorization_uri(
      scope: [:openid, :email],
      state: SecureRandom.hex(16),
      nonce: SecureRandom.hex(16),
      acr_values: 'eidas1'
    )
  end

  def self.user_info(code)
    client = AgentConnectClient.new(code)

    client.access_token!(client_auth_method: :secret)
      .userinfo!
      .raw_attributes
  end
end
