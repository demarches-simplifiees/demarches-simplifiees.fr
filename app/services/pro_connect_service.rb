# frozen_string_literal: true

class ProConnectService
  include OpenIDConnect

  MANDATORY_EMAIL_DOMAINS = []

  def self.enabled?
    ENV['PRO_CONNECT_BASE_URL'].present?
  end

  def self.authorization_uri(force_2fa: false)
    client = OpenIDConnect::Client.new(conf)

    state = SecureRandom.hex(16)
    nonce = SecureRandom.hex(16)

    claims = if force_2fa
      {
        "id_token": {
          "acr": {
            "essential": true,
            "values": [
              "eidas2",
              "eidas3",
              "https://proconnect.gouv.fr/assurance/consistency-checked-2fa",
              "https://proconnect.gouv.fr/assurance/self-asserted-2fa"
            ]
          }
        }
      }
    else
      { id_token: { amr: { essential: true } } }
    end.to_json

    uri = client.authorization_uri(
        scope: [:openid, :email, :given_name, :usual_name, :organizational_unit, :belonging_population, :siret, :idp_id],
        state:,
        nonce:,
        claims:,
        prompt: :login
      )

    [uri, state, nonce]
  end

  def self.user_info(code, nonce)
    client = OpenIDConnect::Client.new(conf)
    client.authorization_code = code

    access_token = client.access_token!(client_auth_method: :secret)

    id_token = ResponseObject::IdToken.decode(access_token.id_token, conf[:jwks])
    id_token.verify!(conf.merge(nonce: nonce))

    amr = id_token.amr.present? ? JSON.parse(id_token.amr) : []

    [access_token.userinfo!.raw_attributes, access_token.id_token, amr]
  end

  def self.logout_url(id_token, host_with_port:)
    app_logout = Rails.application.routes.url_helpers.logout_url(host: host_with_port)
    h = { id_token_hint: id_token, post_logout_redirect_uri: app_logout }
    "#{PRO_CONNECT[:end_session_endpoint]}?#{h.to_query}"
  end

  def self.email_domain_is_in_mandatory_list?(email)
    email.strip.split('@').last.in?(MANDATORY_EMAIL_DOMAINS)
  end

  private

  # TODO: remove this block when migration to new domain is done
  def self.conf
    if Current.host.end_with?('.gouv.fr')
      PRO_CONNECT_GOUV
    else
      PRO_CONNECT
    end
  end
end
