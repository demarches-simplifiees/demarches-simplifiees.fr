OpenIDConnect.debug!
OpenIDConnect.logger = Rails.logger
Rack::OAuth2.logger = Rails.logger
# Webfinger.logger = Rails.logger
SWD.logger = Rails.logger

# the openid_connect gem does not support
# jwt format in the userinfo call.
# A PR is open to improve the situation
# https://github.com/nov/openid_connect/pull/54
module OpenIDConnect
  class AccessToken < Rack::OAuth2::AccessToken::Bearer
    private

    def jwk_loader
      JSON.parse(URI.parse(ENV['AGENT_CONNECT_JWKS']).read).deep_symbolize_keys
    end

    def decode_jwt(requested_host, jwt)
      agent_connect_host = URI.parse(ENV['AGENT_CONNECT_BASE_URL']).host

      if requested_host == agent_connect_host
        # rubocop:disable Lint/UselessAssignment
        JWT.decode(jwt, key = nil, verify = true, { algorithms: ['ES256'], jwks: jwk_loader })[0]
        # rubocop:enable Lint/UselessAssignment
      else
        raise "unknwon host : #{requested_host}"
      end
    end

    def resource_request
      res = yield
      case res.status
      when 200
        hash = case parse_type_and_subtype(res.content_type)
        when 'application/jwt'
          requested_host = URI.parse(client.userinfo_endpoint).host
          decode_jwt(requested_host, res.body)
        when 'application/json'
          JSON.parse(res.body)
        end
        hash&.with_indifferent_access
      when 400
        raise BadRequest.new('API Access Faild', res)
      when 401
        raise Unauthorized.new('Access Token Invalid or Expired', res)
      when 403
        raise Forbidden.new('Insufficient Scope', res)
      else
        raise HttpError.new(res.status, 'Unknown HttpError', res)
      end
    end

    # https://datatracker.ietf.org/doc/html/rfc2045#section-5.1
    # - type and subtype are the first member
    # they are case insensitive
    def parse_type_and_subtype(content_type)
      content_type.split(';')[0].strip.downcase
    end
  end
end
