require 'zxcvbn'

class Administrateurs::ActivateController < ApplicationController
  layout "new_application"

  def new
    @administrateur = Administrateur.find_inactive_by_token(params[:token])

    if !@administrateur
      flash.alert = "Le lien de validation d'administrateur a expiré, #{helpers.contact_link('contactez-nous', tags: 'lien expiré')} pour obtenir un nouveau lien."
      redirect_to root_path
    end
  end

  def create
    password = update_administrateur_params[:password]
    administrateur = Administrateur.reset_password(
      update_administrateur_params[:reset_password_token],
      password
    )

    if administrateur && administrateur.errors.empty?
      sign_in(administrateur, scope: :administrateur)
      try_to_authenticate(User, administrateur.email, password)
      try_to_authenticate(Gestionnaire, administrateur.email, password)
      flash.notice = "Mot de passe enregistré"
      redirect_to admin_procedures_path
    else
      flash.alert = administrateur.errors.full_messages
      redirect_to admin_activate_path(token: update_administrateur_params[:reset_password_token])
    end
  end

  def test_password_strength
    @score = Zxcvbn.test(params[:administrateur][:password], [], ZXCVBN_DICTIONNARIES).score
  end

  private

  def update_administrateur_params
    params.require(:administrateur).permit(:reset_password_token, :password)
  end

  def try_to_authenticate(klass, email, password)
    resource = klass.find_for_database_authentication(email: email)

    if resource&.valid_password?(password)
      sign_in resource
      resource.force_sync_credentials
    end
  end
end
