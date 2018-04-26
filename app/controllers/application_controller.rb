class ApplicationController < ActionController::Base
  MAINTENANCE_MESSAGE = 'Le site est actuellement en maintenance. Il sera à nouveau disponible dans un court instant.'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :load_navbar_left_pannel_partial_url
  before_action :set_raven_context
  before_action :authorize_request_for_profiler
  before_action :reject, if: -> { Flipflop.maintenance_mode? }

  before_action :staging_authenticate

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

  def default_url_options
    return { protocol: 'https' } if Rails.env.staging? || Rails.env.production?
    {}
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

  def logged_users
    @logged_users ||= [
      current_user,
      current_gestionnaire,
      current_administrateur,
      current_administration
    ].compact
  end

  def logged_user_roles
    roles = logged_users.map { |logged_user| logged_user.class.name }
    roles.any? ? roles.join(', ') : 'Guest'
  end

  def logged_user_info
    logged_user = logged_users.first

    if logged_user
      {
        id: logged_user.id,
        email: logged_user.email
      }
    end
  end

  def set_raven_context
    context = {
      ip_address: request.ip,
      roles: logged_user_roles
    }
    context.merge!(logged_user_info || {})

    Raven.user_context(context)
  end

  def append_info_to_payload(payload)
    payload.merge!({
      user_agent: request.user_agent,
      current_user: logged_user_info,
      current_user_roles: logged_user_roles
    }.compact)

    if browser.known?
      payload.merge!({
        browser: browser.name,
        browser_version: browser.version.to_s,
        platform: browser.platform.name,
      })
    end
  end

  def permit_smart_listing_params
    # FIXME: remove when
    # https://github.com/Sology/smart_listing/issues/134
    # is fixed
    self.params = params.permit(
      # Dossiers
      :liste,
      dossiers_smart_listing:
        [
          :page,
          :per_page,
          { sort: [:id, :'procedure.libelle', :state, :updated_at] }
        ],
      # Gestionnaires
      gestionnaires_smart_listing:
        [
          :page,
          :per_page,
          { sort: [:email] }
        ],
      # Procédures
      procedures_smart_listing:
        [
          :page,
          :per_page,
          { sort: [:id, :libelle, :published_at] }
        ]
    )
    # END OF FIXME
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
      %i(user gestionnaire administrateur).each { |role| sign_out(role) }
      flash[:alert] = MAINTENANCE_MESSAGE
      redirect_to root_path
    end
  end
end
