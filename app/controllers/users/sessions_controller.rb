class Users::SessionsController < Devise::SessionsController
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
    user = User.find_by(email: params[:user][:email])

    if user&.valid_password?(params[:user][:password])
      sign_in(user)
      current_user.update(loged_in_with_france_connect: nil)

      set_flash_message :notice, :signed_in
      redirect_to after_sign_in_path_for(:user)
    else
      flash.alert = 'Mauvais couple login / mot de passe'
      render :new, assigns: { user: User.new }
    end
  end

  def link_sent
    @email = params[:email]
  end

  # DELETE /resource/sign_out
  def destroy
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
    instructeur = Instructeur.find(params[:id])
    trusted_device_token = instructeur
      .trusted_device_tokens
      .find_by(token: params[:jeton])

    if trusted_device_token&.token_valid?
      trust_device(trusted_device_token.created_at)

      period = ((trusted_device_token.created_at + TRUSTED_DEVICE_PERIOD) - Time.zone.now).to_i / ActiveSupport::Duration::SECONDS_PER_DAY

      flash.notice = "Merci d’avoir confirmé votre connexion. Votre navigateur est maintenant authentifié pour #{period} jours."

      # redirect to procedure'url if stored by store_location_for(:user) in dossiers_controller
      # redirect to root_path otherwise

      if instructeur_signed_in?
        redirect_to after_sign_in_path_for(:user)
      else
        redirect_to new_user_session_path
      end
    else
      flash[:alert] = 'Votre lien est invalide ou expiré, un nouveau vient de vous être envoyé.'

      send_login_token_or_bufferize(instructeur)
      redirect_to link_sent_path(email: instructeur.email)
    end
  end
end
