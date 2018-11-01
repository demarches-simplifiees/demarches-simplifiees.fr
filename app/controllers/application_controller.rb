class ApplicationController < ActionController::Base
  include AccountConcern

  MAINTENANCE_MESSAGE = 'Le site est actuellement en maintenance. Il sera à nouveau disponible dans un court instant.'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, if: -> { !Rails.env.test? }
  before_action :load_navbar_left_pannel_partial_url
  before_action :set_raven_context
  before_action :authorize_request_for_profiler
  before_action :reject, if: -> { Flipflop.maintenance_mode? }

  before_action :staging_authenticate
  before_action :set_active_storage_host

  def staging_authenticate
    if StagingAuthService.enabled? && !authenticate_with_http_basic { |username, password| StagingAuthService.authenticate(username, password) }
      request_http_basic_authentication
    end
  end

  def authorize_request_for_profiler
    if manager_signed_in?
      Rack::MiniProfiler.authorize_request
    end
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

  def after_sign_out_path_for(_resource_or_scope)
    stored_location_for(:user) || super
  end

  private

  def set_active_storage_host
    ActiveStorage::Current.host = request.base_url
  end

  def set_raven_context
    context = {
      ip_address: request.ip,
      id: current_account.id,
      email: current_account.email,
      roles: current_account.role_names
    }.compact

    Raven.user_context(context)
  end

  def append_info_to_payload(payload)
    super
    payload.merge!({
      user_agent: request.user_agent,
      user_id: current_account.id,
      user_email: current_account.email,
      user_roles: current_account.role_names
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

  def reject
    authorized_request =
      request.path_info == '/' ||
      request.path_info.start_with?('/manager') ||
      request.path_info.start_with?('/administrations')

    api_request = request.path_info.start_with?('/api/')

    if manager_signed_in? || authorized_request
      flash.now.alert = MAINTENANCE_MESSAGE
    elsif api_request
      render json: { error: MAINTENANCE_MESSAGE }.to_json, status: :service_unavailable
    else
      sign_out!
      flash[:alert] = MAINTENANCE_MESSAGE
      redirect_to root_path
    end
  end
end
