# frozen_string_literal: true

require "administrate/field/base"

class JwtField < Administrate::Field::Base
  def to_s
    if data.present?
      begin
        decoded_token = JWT.decode(data, nil, false)

        return "Token présent, sans expiration" unless decoded_token[0].key?('exp')

        expiration = Time.zone.at(decoded_token[0]['exp'])
        if expiration < Time.zone.now
          "Token présent, expiré le #{expiration.strftime('%d/%m/%Y à %H:%M')}"
        else
          "Token présent, expirera le #{expiration.strftime('%d/%m/%Y à %H:%M')}"
        end
      rescue JWT::DecodeError => e
        "Token invalide : #{e.message}"
      end
    else
      "Pas de token"
    end
  end
end
