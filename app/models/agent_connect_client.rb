class AgentConnectClient < OpenIDConnect::Client
  def initialize
    super(AGENT_CONNECT)
  end
end
