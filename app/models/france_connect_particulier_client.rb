# frozen_string_literal: true

class FranceConnectParticulierClient < OpenIDConnect::Client
  def initialize(code = nil)
    config = FRANCE_CONNECT[:particulier].deep_dup

    # TODO: remove this block when migration to new domain is done
    # dirty hack to redirect to the right domain
    if !Rails.env.test? && Current.host != ENV.fetch("APP_HOST")
      config[:redirect_uri] = config[:redirect_uri].gsub(ENV.fetch("APP_HOST"), Current.host)
    end

    super(config)

    if code.present?
      self.authorization_code = code
    end
  end
end
