# frozen_string_literal: true

class APIEntrepriseToken
  include ActiveModel::Validations

  validates :jwt_token, jwt_token: true, allow_blank: true

  TokenError = Class.new(StandardError)

  SOON_TO_EXPIRE_DELAY = 1.month

  attr_reader :jwt_token

  def initialize(jwt_token)
    @jwt_token = jwt_token
  end

  def expired?
    return true if @jwt_token.blank?

    decoded_token.key?("exp") && decoded_token["exp"] <= Time.zone.now.to_i
  end

  def expires_at
    return nil if @jwt_token.blank?

    decoded_token.key?("exp") && Time.zone.at(decoded_token["exp"])
  end

  def expired_or_expires_soon?
    expires_at && expires_at <= SOON_TO_EXPIRE_DELAY.from_now
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
    return [] if @jwt_token.blank?

    Array(decoded_token["roles"] || decoded_token["scopes"])
  end

  def decoded_token
    @decoded_token ||= {}
    @decoded_token[@jwt_token] ||= JWT.decode(@jwt_token, nil, false)[0]
  rescue JWT::DecodeError => e
    raise TokenError, e.message
  end
end
