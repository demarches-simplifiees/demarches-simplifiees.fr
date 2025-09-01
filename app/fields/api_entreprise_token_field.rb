# frozen_string_literal: true

require "administrate/field/base"

class APIEntrepriseTokenField < Administrate::Field::Base
  def to_s
    token = data
    if token.jwt_token.present?
      expires_at = token.expires_at
      return "Token présent, sans expiration" if expires_at.nil?
      return "Token présent, expiré le #{expires_at.strftime('%d/%m/%Y à %H:%M')}" if token.expired?
      return "Token présent, expirera le #{expires_at.strftime('%d/%m/%Y à %H:%M')}"

    else
      "Pas de token"
    end
  end
end
