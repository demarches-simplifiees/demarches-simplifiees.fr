class Instructeurs::ActivateController < ApplicationController
  include TrustedDeviceConcern

  def new
    @instructeur = Instructeur.with_reset_password_token(params[:token])

    if @instructeur
      # the instructeur activates its account from an email
      trust_device(Time.zone.now)
    else
      flash.alert = "Le lien de validation du compte instructeur a expiré, #{helpers.contact_link('contactez-nous', tags: 'lien expiré')} pour obtenir un nouveau lien."
      redirect_to root_path
    end
  end

  def create
    password = create_instructeur_params[:password]
    instructeur = Instructeur.reset_password_by_token({
      password: password,
      password_confirmation: password,
      reset_password_token: create_instructeur_params[:reset_password_token]
    })

    if instructeur && instructeur.errors.empty?
      sign_in(instructeur, scope: :instructeur)
      try_to_authenticate(User, instructeur.email, password)
      try_to_authenticate(Administrateur, instructeur.email, password)
      flash.notice = "Mot de passe enregistré"
      redirect_to instructeur_procedures_path
    else
      flash.alert = instructeur.errors.full_messages
      redirect_to instructeur_activate_path(token: create_instructeur_params[:reset_password_token])
    end
  end

  private

  def create_instructeur_params
    params.require(:instructeur).permit(:reset_password_token, :password)
  end

  def try_to_authenticate(klass, email, password)
    resource = klass.find_for_database_authentication(email: email)

    if resource&.valid_password?(password)
      sign_in resource
      resource.force_sync_credentials
    end
  end
end
