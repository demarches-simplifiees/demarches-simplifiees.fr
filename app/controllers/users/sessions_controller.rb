class Users::SessionsController < Sessions::SessionsController
  include ProcedureContextConcern
  include TrustedDeviceConcern
  include ActionView::Helpers::DateHelper

  layout 'procedure_context', only: [:new, :create]

  before_action :restore_procedure_context, only: [:new, :create]

  # GET /resource/sign_in
  def new
    @user = User.new
  end

  # POST /resource/sign_in
  def create
    remember_me = params[:user][:remember_me] == '1'
    try_to_authenticate(User, remember_me)
    try_to_authenticate(Gestionnaire, remember_me)
    try_to_authenticate(Administrateur, remember_me)

    if user_signed_in?
      current_user.update(loged_in_with_france_connect: nil)
    end

    if gestionnaire_signed_in?
      if trusted_device? || !current_gestionnaire.feature_enabled?(:enable_email_login_token)
        set_flash_message :notice, :signed_in
        redirect_to after_sign_in_path_for(:user)
      else
        gestionnaire = current_gestionnaire

        send_login_token_or_bufferize(gestionnaire)

        [:user, :gestionnaire, :administrateur].each { |role| sign_out(role) }

        redirect_to link_sent_path(email: gestionnaire.email)
      end
    elsif user_signed_in?
      set_flash_message :notice, :signed_in
      redirect_to after_sign_in_path_for(:user)
    else
      flash.alert = 'Mauvais couple login / mot de passe'
      new
      render :new, status: 401
    end
  end

  def link_sent
    @email = params[:email]
  end

  # DELETE /resource/sign_out
  def destroy
    if gestionnaire_signed_in?
      sign_out :gestionnaire
    end

    if administrateur_signed_in?
      sign_out :administrateur
    end

    if user_signed_in?
      connected_with_france_connect = current_user.loged_in_with_france_connect
      current_user.update(loged_in_with_france_connect: '')

      sign_out :user

      case connected_with_france_connect
      when User.loged_in_with_france_connects.fetch(:particulier)
        redirect_to FRANCE_CONNECT[:particulier][:logout_endpoint]
        return
      end
    end

    respond_to_on_destroy
  end

  def no_procedure
    clear_stored_location_for(:user)
    redirect_to new_user_session_path
  end

  def sign_in_by_link
    gestionnaire = Gestionnaire.find(params[:id])
    if gestionnaire&.login_token_valid?(params[:jeton])
      trust_device
      flash.notice = "Merci d’avoir confirmé votre connexion. Votre navigateur est maintenant authentifié pour #{TRUSTED_DEVICE_PERIOD.to_i / ActiveSupport::Duration::SECONDS_PER_DAY} jours."

      user = User.find_by(email: gestionnaire.email)
      administrateur = Administrateur.find_by(email: gestionnaire.email)
      [user, gestionnaire, administrateur].compact.each { |resource| sign_in(resource) }

      # redirect to procedure'url if stored by store_location_for(:user) in dossiers_controller
      # redirect to root_path otherwise
      redirect_to after_sign_in_path_for(:user)
    else
      flash[:alert] = 'Votre lien est invalide ou expiré, veuillez-vous reconnecter.'
      redirect_to new_user_session_path
    end
  end

  private

  def send_login_token_or_bufferize(gestionnaire)
    if !gestionnaire.young_login_token?
      login_token = gestionnaire.login_token!
      GestionnaireMailer.send_login_token(gestionnaire, login_token).deliver_later
    end
  end

  def try_to_authenticate(klass, remember_me = false)
    resource = klass.find_for_database_authentication(email: params[:user][:email])

    if resource.present?
      if resource.valid_password?(params[:user][:password])
        resource.remember_me = remember_me
        sign_in resource
        resource.force_sync_credentials
      end
    end
  end
end
