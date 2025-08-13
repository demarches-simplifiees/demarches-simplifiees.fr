# frozen_string_literal: true

class FranceConnectService
  def self.enabled?
    ENV.fetch("FRANCE_CONNECT_ENABLED", "enabled") == "enabled"
  end

  def self.authorization_uri(conf_id)
    client = OpenIDConnect::Client.new(conf_with_redirect_override(conf_id))

    state = SecureRandom.alphanumeric(32)
    nonce = SecureRandom.alphanumeric(32)

    uri = client.authorization_uri(
      scope: [:profile, :email],
      state:,
      nonce:,
      acr_values: 'eidas1'
    )

    [uri, state, nonce]
  end

  def self.find_or_retrieve_france_connect_information(code, nonce, conf_id)
    fetched_fci, id_token = retrieve_user_informations(code, nonce, conf_id)
    fci_to_return = FranceConnectInformation.find_by(france_connect_particulier_id: fetched_fci[:france_connect_particulier_id]) || fetched_fci
    [fci_to_return, id_token]
  end

  def self.logout_url(id_token:, state:, callback:)
    h = { id_token_hint: id_token, state:, post_logout_redirect_uri: callback }
    "#{conf(nil)[:end_session_endpoint]}?#{h.to_query}"
  end

  private

  def self.retrieve_user_informations(code, nonce, conf_id)
    client = OpenIDConnect::Client.new(conf_with_redirect_override(conf_id))
    client.authorization_code = code

    access_token = client.access_token!(client_auth_method: :secret)

    id_token = OpenIDConnect::ResponseObject::IdToken.decode(access_token.id_token, conf(conf_id)[:jwks])

    id_token.verify!(conf(conf_id).merge(nonce:))

    user_info = access_token.userinfo!.raw_attributes

    fci = FranceConnectInformation.new(
      gender: user_info[:gender],
      given_name: user_info[:given_name],
      family_name: user_info[:family_name],
      email_france_connect: user_info[:email],
      birthdate: user_info[:birthdate],
      birthplace: user_info[:birthplace],
      france_connect_particulier_id: user_info[:sub]
    )

    [fci, access_token.id_token]
  end

  def self.conf_with_redirect_override(conf_id)
    config = conf(conf_id).deep_dup

    # TODO: remove this block when migration to new domain is done
    # dirty hack to redirect to the right domain
    if !Rails.env.test? && Current.host != ENV.fetch("APP_HOST")
      config[:redirect_uri] = config[:redirect_uri].gsub(ENV.fetch("APP_HOST"), Current.host)
    end

    config
  end

  def self.conf(id)
    if id == 'MOLENE'
      FRANCE_CONNECT_DISCOVER.merge(
        client_id: ENV.fetch('FC_MOLENE_ID_V2'),
        identifier: ENV.fetch('FC_MOLENE_ID_V2'),
        secret: ENV.fetch('FC_MOLENE_SECRET_V2')
      )
    elsif id == "Monts d'Arrée"
      FRANCE_CONNECT_DISCOVER.merge(
        client_id: ENV.fetch('FC_ARREE_ID_V2'),
        identifier: ENV.fetch('FC_ARREE_ID_V2'),
        secret: ENV.fetch('FC_ARREE_SECRET_V2')
      )
    else
      FRANCE_CONNECT
    end
  end
end
