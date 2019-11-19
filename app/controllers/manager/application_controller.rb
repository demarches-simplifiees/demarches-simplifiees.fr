module Manager
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_administration!
    before_action :default_params

    def default_params
      params[resource_name] ||= {
        order: "created_at",
        direction: "desc"
      }
    end

    protected

    def authenticate_administration!
      if administration_signed_in?
        super
      else
        redirect_to manager_sign_in_path
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
