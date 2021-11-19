class AgentConnectService
  def self.enabled?
    ENV.fetch("AGENT_CONNECT_ENABLED", "enabled") == "enabled"
  end
end
