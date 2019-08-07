class Users::ActivateController < ApplicationController
  include TrustedDeviceConcern

  def new
    @user = User.with_reset_password_token(params[:token])

    if @user
      # the user activates its account from an email
      trust_device(Time.zone.now)
    else
      flash.alert = "Le lien de validation du compte instructeur a expiré, #{helpers.contact_link('contactez-nous', tags: 'lien expiré')} pour obtenir un nouveau lien."
      redirect_to root_path
    end
  end

  def create
    password = create_user_params[:password]
    user = User.reset_password_by_token({
      password: password,
      password_confirmation: password,
      reset_password_token: create_user_params[:reset_password_token]
    })

    if user && user.errors.empty?
      sign_in(user, scope: :user)
      try_to_authenticate(Administrateur, user.email, password)
      flash.notice = "Mot de passe enregistré"
      redirect_to instructeur_procedures_path
    else
      flash.alert = user.errors.full_messages
      redirect_to users_activate_path(token: create_user_params[:reset_password_token])
    end
  end

  private

  def create_user_params
    params.require(:user).permit(:reset_password_token, :password)
  end

  def try_to_authenticate(klass, email, password)
    resource = klass.find_for_database_authentication(email: email)

    if resource&.valid_password?(password)
      sign_in resource
      resource.force_sync_credentials
    end
  end
end
