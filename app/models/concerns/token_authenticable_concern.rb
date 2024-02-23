# frozen_string_literal: true

module TokenAuthenticableConcern
  extend ActiveSupport::Concern

  included do
    AUTHENTICABLE_TOKEN_LIFETIME = 5.minutes

    def authenticable_token
      secret = sign_in_secret.presence || reset_sign_in_secret!

      payload = {
        user_id: id,
        sign_in_secret: secret
      }

      self.class.token_authenticable_verifier.generate(payload, expires_in: AUTHENTICABLE_TOKEN_LIFETIME)
    end

    def reset_sign_in_secret!
      update!(sign_in_secret: SecureRandom.base64(32))
      sign_in_secret
    end

    def clear_sign_in_secret!
      update!(sign_in_secret: nil)
    end
  end

  class_methods do
    def token_authenticable_verifier
      Rails.application.message_verifier(:token_authenticable)
    end

    def find_by_authenticable_token(token)
      decoded_token = decode_authenticable_token(token)

      return if decoded_token.blank?

      find_by(id: decoded_token.fetch(:user_id),
              sign_in_secret: decoded_token.fetch(:sign_in_secret))
    end

    def decode_authenticable_token(token)
      token_authenticable_verifier.verify(token)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      {}.freeze
    end
  end
end
