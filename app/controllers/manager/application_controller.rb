module Manager
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_administration!
    before_action :default_params

    def default_params
      params[:order] ||= "created_at"
      params[:direction] ||= "desc"
    end

    protected

    def authenticate_administration!
      if administration_signed_in?
        super
      else
        redirect_to manager_sign_in_path
      end
    end
  end
end
