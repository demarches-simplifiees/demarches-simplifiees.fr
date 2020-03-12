class OmniAuthClient < OpenIDConnect::Client
  def initialize(connection_keys, code = nil)
    super(connection_keys)

    if code.present?
      self.authorization_code = code
    end
  end
end
