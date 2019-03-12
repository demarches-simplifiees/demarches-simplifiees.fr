class ApplicationController < ActionController::Base
  include TrustedDeviceConcern

  MAINTENANCE_MESSAGE = 'Le site est actuellement en maintenance. Il sera à nouveau disponible dans un court instant.'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, if: -> { !Rails.env.test? }
  before_action :set_current_roles
  before_action :load_navbar_left_pannel_partial_url
  before_action :set_raven_context
  before_action :redirect_if_untrusted
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
    if administration_signed_in?
      Rack::MiniProfiler.authorize_request
    end
  end

  def load_navbar_left_pannel_partial_url
    controller = request.controller_class
    method = params[:action]
    service = RenderPartialService.new(controller, method)
    @navbar_url = service.navbar
    @left_pannel_url = service.left_panel
  end

  def logged_in?
    logged_user.present?
  end

  def logged_user_ids
    logged_users.map(&:id)
  end

  helper_method :logged_in?

  protected

  def authenticate_logged_user!
    if gestionnaire_signed_in?
      authenticate_gestionnaire!
    elsif administrateur_signed_in?
      authenticate_administrateur!
    else
      authenticate_user!
    end
  end

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

  def after_sign_out_path_for(_resource_or_scope)
    stored_location_for(:user) || super
  end

  private

  def set_current_roles
    Current.administrateur = current_administrateur
    Current.gestionnaire = current_gestionnaire
  end

  def set_active_storage_host
    ActiveStorage::Current.host = request.base_url
  end

  def logged_users
    @logged_users ||= [
      current_user,
      current_gestionnaire,
      current_administrateur,
      current_administration
    ].compact
  end

  def logged_user
    logged_users.first
  end

  def logged_user_roles
    roles = logged_users.map { |logged_user| logged_user.class.name }
    roles.any? ? roles.join(', ') : 'Guest'
  end

  def set_raven_context
    user = logged_user

    context = {
      ip_address: request.ip,
      id: user&.id,
      email: user&.email,
      roles: logged_user_roles
    }.compact

    Raven.user_context(context)
  end

  def append_info_to_payload(payload)
    super
    user = logged_user

    payload.merge!({
      user_agent: request.user_agent,
      user_id: user&.id,
      user_email: user&.email,
      user_roles: logged_user_roles
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

    if administration_signed_in? || authorized_request
      flash.now.alert = MAINTENANCE_MESSAGE
    elsif api_request
      render json: { error: MAINTENANCE_MESSAGE }.to_json, status: :service_unavailable
    else
      [:user, :gestionnaire, :administrateur].each { |role| sign_out(role) }
      flash[:alert] = MAINTENANCE_MESSAGE
      redirect_to root_path
    end
  end

  def redirect_if_untrusted
    if gestionnaire_signed_in? &&
        sensitive_path &&
        Flipflop.enable_email_login_token? &&
        !trusted_device?

      # return at this location
      # after the device is trusted
      store_location_for(:user, request.fullpath)

      send_login_token_or_bufferize(current_gestionnaire)
      redirect_to link_sent_path(email: current_gestionnaire.email)
    end
  end

  def sensitive_path
    path = request.path_info

    if path == '/' ||
      path == '/users/sign_out' ||
      path.start_with?('/connexion-par-jeton') ||
      path.start_with?('/api/') ||
      path.start_with?('/lien-envoye')

      false
    else
      true
    end
  end
end
