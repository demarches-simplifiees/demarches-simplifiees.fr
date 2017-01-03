class Users::SessionsController < Sessions::SessionsController
# before_action :configure_sign_in_params, only: [:create]

  def demo
    return redirect_to root_path if Rails.env.production?

    @user = User.new(email: DemoEmails[:user], password: 'password')
    render 'new'
  end

# GET /resource/sign_in
  def new
    unless user_return_to_procedure_id.nil?
      @dossier = Dossier.new(procedure: Procedure.active(user_return_to_procedure_id))
    end

    @user = User.new
  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

#POST /resource/sign_in
  def create
    try_to_authenticate(User)
    try_to_authenticate(Gestionnaire)
    try_to_authenticate(Administrateur)

    if user_signed_in?
      current_user.update_attributes(loged_in_with_france_connect: '')
    end

    if user_signed_in?
      redirect_to after_sign_in_path_for(:user)
    elsif gestionnaire_signed_in?
      redirect_to backoffice_path
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
    sign_out :gestionnaire if gestionnaire_signed_in?
    sign_out :administrateur if administrateur_signed_in?

    if user_signed_in?
      connected_with_france_connect = current_user.loged_in_with_france_connect
      current_user.update_attributes(loged_in_with_france_connect: '')

      sign_out :user

      if connected_with_france_connect == 'entreprise'
        redirect_to FRANCE_CONNECT.entreprise_logout_endpoint
        return
      elsif connected_with_france_connect == 'particulier'
        redirect_to FRANCE_CONNECT.particulier_logout_endpoint
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
    flash.alert = t('errors.messages.procedure_not_found')
    redirect_to url_for root_path
  end

  def user_return_to_procedure_id
    return nil if session["user_return_to"].nil?

    NumberService.to_number session["user_return_to"].split("?procedure_id=").second
  end

  def try_to_authenticate(klass)
    if resource = klass.find_for_database_authentication(email: params[:user][:email])
      if resource.valid_password?(params[:user][:password])
        sign_in resource
        set_flash_message :notice, :signed_in
      end
    end
  end
end
