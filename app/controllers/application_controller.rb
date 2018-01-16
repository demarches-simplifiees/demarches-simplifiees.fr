class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :check_browser
  before_action :load_navbar_left_pannel_partial_url
  before_action :set_raven_context
  before_action :authorize_request_for_profiler

  def authorize_request_for_profiler
    if administration_signed_in?
      Rack::MiniProfiler.authorize_request
    end
  end

  def default_url_options
    return { protocol: 'https' } if Rails.env.staging? || Rails.env.production?
    {}
  end

  def check_browser
    BROWSER.value = BrowserService.get_browser(request)
  end

  def load_navbar_left_pannel_partial_url
    controller = request.controller_class
    method = params[:action]
    service = RenderPartialService.new(controller, method)
    @navbar_url = service.navbar
    @left_pannel_url = service.left_panel
    @facade_data_view = nil
  end

  protected

  def authenticate_gestionnaire!
    if gestionnaire_signed_in?
      super
    else
      redirect_to new_user_session_path
    end
  end

  def authenticate_administrateur!
    if administrateur_signed_in?
      super
    else
      redirect_to new_user_session_path
    end
  end

  private

  def set_raven_context
    context = { ip_address: request.ip }

    logged_models = [
      current_user,
      current_gestionnaire,
      current_administrateur,
      current_administration
    ].compact

    context[:email] = logged_models.first&.email
    context[:id]    = logged_models.first&.id

    class_names = logged_models.map { |model| model.class.name }
    context[:classes] = class_names.any? ? class_names.join(', ') : 'Guest'

    Raven.user_context(context)
  end
end
