# frozen_string_literal: true

module FranceConnectConcern
  extend ActiveSupport::Concern

  included do
    def logged_in_with_france_connect?
      cookies.encrypted[FranceConnectController::ID_TOKEN_COOKIE_NAME].present?
    end

    def france_connect_logout_url(callback:)
      id_token = cookies.encrypted[FranceConnectController::ID_TOKEN_COOKIE_NAME]
      state = cookies.encrypted[FranceConnectController::STATE_COOKIE_NAME]

      cookies.delete(FranceConnectController::ID_TOKEN_COOKIE_NAME)
      cookies.delete(FranceConnectController::STATE_COOKIE_NAME)
      cookies.delete(FranceConnectController::CONF_ID_COOKIE_NAME)

      FranceConnectService.logout_url(id_token:, state:, callback:)
    end

    def delete_france_connect_cookies
      cookies.delete(FranceConnectController::ID_TOKEN_COOKIE_NAME)
      cookies.delete(FranceConnectController::STATE_COOKIE_NAME)
    end
  end
end
