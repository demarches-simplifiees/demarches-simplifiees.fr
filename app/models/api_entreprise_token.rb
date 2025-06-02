# frozen_string_literal: true

class APIEntrepriseToken
  TokenError = Class.new(StandardError)

  def initialize(token)
    @token = token
  end

  def token
    # Pf: token entreprise not initialized
    # raise TokenError, I18n.t("api_entreprise.errors.missing_token") if @token.blank?
    Rails.logger.warn(I18n.t("api_entreprise.errors.missing_token")) if @token.blank?

    @token
  end

  def expired?
    # Pf: check if token is present
    token.present? && decoded_token.key?("exp") && decoded_token["exp"] <= Time.zone.now.to_i
  end

  def role?(role)
    # Pf check if token is present
    token.present? && roles.present? && roles.include?(role)
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
