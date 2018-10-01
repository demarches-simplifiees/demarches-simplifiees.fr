class Users::SessionsController < Sessions::SessionsController
  layout "new_application"

  # GET /resource/sign_in
  def new
    if user_return_to_procedure_id.present? # WTF ?
      @dossier = Dossier.new(procedure: Procedure.active(user_return_to_procedure_id))
    end

    @user = User.new
  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

  # POST /resource/sign_in
  def create
    remember_me = params[:user][:remember_me] == '1'
    try_to_authenticate(User, remember_me)
    try_to_authenticate(Gestionnaire, remember_me)
    try_to_authenticate(Administrateur, remember_me)

    if user_signed_in?
      current_user.update(loged_in_with_france_connect: '')
    end

    if user_signed_in?
      redirect_to after_sign_in_path_for(:user)
    elsif gestionnaire_signed_in?
      location = stored_location_for(:gestionnaire) || gestionnaire_procedures_path
      redirect_to location
    elsif administrateur_signed_in?
      redirect_to admin_path
    else
      flash.alert = 'Mauvais couple login / mot de passe'
      new
      render :new, status: 401
    end
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
    session['user_return_to'] = nil
    redirect_to new_user_session_path
  end

  private

  def error_procedure
    session["user_return_to"] = nil
    flash.alert = t('errors.messages.procedure_not_found')
    redirect_to url_for root_path
  end

  def user_return_to_procedure_id
    if session["user_return_to"].nil?
      return nil
    end

    NumberService.to_number session["user_return_to"].split("?procedure_id=").second
  end

  def try_to_authenticate(klass, remember_me = false)
    resource = klass.find_for_database_authentication(email: params[:user][:email])

    if resource.present?
      if resource.valid_password?(params[:user][:password])
        resource.remember_me = remember_me
        sign_in resource
        resource.force_sync_credentials
        set_flash_message :notice, :signed_in
      end
    end
  end
end
