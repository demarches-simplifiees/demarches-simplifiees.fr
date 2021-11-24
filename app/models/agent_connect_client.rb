class AgentConnectClient < OpenIDConnect::Client
  def initialize(code = nil)
    super(AGENT_CONNECT)

    if code.present?
      self.authorization_code = code
    end
  end
end
