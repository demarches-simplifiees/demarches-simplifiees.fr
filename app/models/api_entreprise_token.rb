# frozen_string_literal: true

class APIEntrepriseToken
  TokenError = Class.new(StandardError)

  def initialize(token)
    @token = token
  end

  def token
    raise TokenError, I18n.t("api_entreprise.errors.missing_token") if @token.blank?

    @token
  end

  def expired?
    decoded_token.key?("exp") && decoded_token["exp"] <= Time.zone.now.to_i
  end

  def expiration
    decoded_token.key?("exp") && Time.zone.at(decoded_token["exp"])
  end

  def can_fetch_attestation_sociale?
    # https://github.com/etalab/admin_api_entreprise/blob/6f5c7ecbe94af8d5403dbff320af56e8797f3fc6/app/policies/download_attestations_policy.rb#L16
    ['attestation_sociale', 'attestation_sociale_urssaf']
      .any? { |r| roles.include?(r) }
  end

  def can_fetch_attestation_fiscale?
    # https://github.com/etalab/admin_api_entreprise/blob/6f5c7ecbe94af8d5403dbff320af56e8797f3fc6/app/policies/download_attestations_policy.rb#L20
    ["attestation_fiscale", "attestation_fiscale_dgfip"]
      .any? { |r| roles.include?(r) }
  end

  def can_fetch_bilans_bdf?
    roles.include?("bilans_entreprise_bdf")
  end

  private

  def roles
    Array(decoded_token["roles"] || decoded_token["scopes"])
  end

  def decoded_token
    @decoded_token ||= {}
    @decoded_token[token] ||= JWT.decode(token, nil, false)[0]
  rescue JWT::DecodeError => e
    raise TokenError, e.message
  end
end
