class FranceConnectParticulierClient < OpenIDConnect::Client
  def initialize(code = nil)
    super(FRANCE_CONNECT[:particulier])

    if code.present?
      self.authorization_code = code
    end
  end
end
