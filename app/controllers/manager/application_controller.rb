# frozen_string_literal: true

module Manager
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_super_admin!
    before_action :default_params

    def default_params
      request.query_parameters[resource_name] ||= {
        order: "id",
        direction: "desc"
      }
    end

    protected

    def authenticate_super_admin!
      if super_admin_signed_in? && current_super_admin.otp_required_for_login?
        super
      elsif super_admin_signed_in?
        SUPER_ADMIN_OTP_ENABLED ? (redirect_to edit_super_admin_otp_path) : super
      else
        redirect_to new_super_admin_session_path
      end
    end

    private

    def sorting_attribute
      attribute = super

      # do not sort by non-indexed created_at. This require a full table scan, locking every other transactions.
      return :id if attribute.to_sym == :created_at

      attribute
    end

    # private method called by rails fwk
    # see https://github.com/roidrage/lograge
    def append_info_to_payload(payload)
      super

      to_log = {
        user_agent: request.user_agent,
        user_id: current_user&.id,
        user_email: current_user&.email
      }

      if browser.known?
        to_log.merge!({
          browser: browser.name,
          browser_version: browser.version.to_s,
          platform: browser.platform.name
        })
      end

      payload[:to_log] = to_log
    end
  end
end
