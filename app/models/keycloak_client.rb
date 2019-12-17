class KeycloakClient < OpenIDConnect::Client
  def initialize(code = nil)
    super(Rails.application.secrets.keycloak)

    if code.present?
      self.authorization_code = code
    end
  end
end
