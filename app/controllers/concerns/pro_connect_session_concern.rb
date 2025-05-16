# frozen_string_literal: true

module ProConnectSessionConcern
  extend ActiveSupport::Concern

  SESSION_INFO_COOKIE_NAME = :pro_connect_session_info

  included do
    def logged_in_with_pro_connect?
      current_user.present? && cookies.encrypted[SESSION_INFO_COOKIE_NAME].present? && JSON.parse(cookies.encrypted[SESSION_INFO_COOKIE_NAME])['user_id'] == current_user.id
    end

    def set_pro_connect_session_info_cookie(user_id)
      cookies.encrypted[SESSION_INFO_COOKIE_NAME] = { value: { user_id: }.to_json, secure: Rails.env.production?, httponly: true }
    end

    def delete_pro_connect_session_info_cookie
      cookies.delete SESSION_INFO_COOKIE_NAME
    end
  end
end
