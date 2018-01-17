module Manager
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_administration!
    before_action :default_params

    def default_params
      params[:order] ||= "created_at"
      params[:direction] ||= "desc"
    end
  end
end
