class Gestionnaires::ActivateController < ApplicationController
  include TrustedDeviceConcern

  def new
    @gestionnaire = Gestionnaire.with_reset_password_token(params[:token])

    if @gestionnaire
      # the gestionnaire activates its account from an email
      trust_device
    else
      flash.alert = "Le lien de validation du compte instructeur a expiré, #{helpers.contact_link('contactez-nous', tags: 'lien expiré')} pour obtenir un nouveau lien."
      redirect_to root_path
    end
  end

  def create
    password = create_gestionnaire_params[:password]
    gestionnaire = Gestionnaire.reset_password_by_token({
      password: password,
      password_confirmation: password,
      reset_password_token: create_gestionnaire_params[:reset_password_token]
    })

    if gestionnaire && gestionnaire.errors.empty?
      sign_in(gestionnaire, scope: :gestionnaire)
      try_to_authenticate(User, gestionnaire.email, password)
      try_to_authenticate(Administrateur, gestionnaire.email, password)
      flash.notice = "Mot de passe enregistré"
      redirect_to gestionnaire_procedures_path
    else
      flash.alert = gestionnaire.errors.full_messages
      redirect_to gestionnaire_activate_path(token: create_gestionnaire_params[:reset_password_token])
    end
  end

  private

  def create_gestionnaire_params
    params.require(:gestionnaire).permit(:reset_password_token, :password)
  end

  def try_to_authenticate(klass, email, password)
    resource = klass.find_for_database_authentication(email: email)

    if resource&.valid_password?(password)
      sign_in resource
      resource.force_sync_credentials
    end
  end
end
