# frozen_string_literal: true

module ProConnectSessionConcern
  extend ActiveSupport::Concern

  SESSION_INFO_COOKIE_NAME = :pro_connect_session_info

  included do
    helper_method :logged_in_with_pro_connect?

    def set_pro_connect_session_info_cookie(user_id, mfa: false)
      value = { user_id:, mfa: }.to_json
      cookies.encrypted[SESSION_INFO_COOKIE_NAME] = { value:, secure: Rails.env.production?, httponly: true }
    end

    def logged_in_with_pro_connect?
      pro_connect_session.present?
    end

    def pro_connect_mfa?
      pro_connect_session['mfa'] == true
    end

    def delete_pro_connect_session_info_cookie
      cookies.delete SESSION_INFO_COOKIE_NAME
    end
  end

  private

  def pro_connect_session
    session = if cookies.encrypted[SESSION_INFO_COOKIE_NAME].present?
      JSON.parse(cookies.encrypted[SESSION_INFO_COOKIE_NAME])
    else
      {}
    end

    session['user_id'] == current_user.id ? session : {}
  end
end
