module Manager
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_super_admin!
    before_action :default_params

    def default_params
      params[resource_name] ||= {
        order: "created_at",
        direction: "desc"
      }
    end

    protected

    def authenticate_super_admin!
      if super_admin_signed_in? && current_super_admin.otp_required_for_login?
        super
      elsif super_admin_signed_in?
        redirect_to edit_super_admin_otp_path
      else
        redirect_to new_super_admin_session_path
      end
    end

    private

    # private method called by rails fwk
    # see https://github.com/roidrage/lograge
    def append_info_to_payload(payload)
      super

      payload.merge!({
        user_agent: request.user_agent,
        user_id: current_user&.id,
        user_email: current_user&.email
      }.compact)

      if browser.known?
        payload.merge!({
          browser: browser.name,
          browser_version: browser.version.to_s,
          platform: browser.platform.name
        })
      end

      payload
    end
  end
end
