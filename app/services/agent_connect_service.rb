# frozen_string_literal: true

class AgentConnectService
  include OpenIDConnect

  def self.enabled?
    ENV['AGENT_CONNECT_BASE_URL'].present?
  end

  def self.authorization_uri
    client = OpenIDConnect::Client.new(conf)

    state = SecureRandom.hex(16)
    nonce = SecureRandom.hex(16)

    uri = client.authorization_uri(
      scope: [:openid, :email, :given_name, :usual_name, :organizational_unit, :belonging_population, :siret],
      state:,
      nonce:,
      acr_values: 'eidas1'
    )

    [uri, state, nonce]
  end

  def self.user_info(code, nonce)
    client = OpenIDConnect::Client.new(conf)
    client.authorization_code = code

    access_token = client.access_token!(client_auth_method: :secret)

    id_token = ResponseObject::IdToken.decode(access_token.id_token, conf[:jwks])
    id_token.verify!(conf.merge(nonce: nonce))

    [access_token.userinfo!.raw_attributes, access_token.id_token]
  end

  private

  # TODO: remove this block when migration to new domain is done
  def self.conf
    if Current.host.end_with?('.gouv.fr')
      AGENT_CONNECT_GOUV
    else
      AGENT_CONNECT
    end
  end
end
