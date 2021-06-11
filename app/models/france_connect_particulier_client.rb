class FranceConnectParticulierClient < OpenIDConnect::Client
  def initialize(code = nil, credentials = nil)
    credentials ||= Rails.application.secrets.france_connect_particulier
    super(Rails.configuration.x.fcp.merge(credentials))
    @authorization_code = code.presence
  end

  attr_reader :authorization_code
end
