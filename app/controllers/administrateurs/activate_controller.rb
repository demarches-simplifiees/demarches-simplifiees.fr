class Administrateurs::ActivateController < ApplicationController
  layout "new_application"

  def new
    @administrateur = Administrateur.find_inactive_by_token(params[:token])

    if !@administrateur
      flash.alert = "Le lien de validation d'administrateur a expiré, contactez-nous à contact@demarches-simplifiees.fr pour obtenir un nouveau lien."
      redirect_to root_path
    end
  end

  def create
    administrateur = Administrateur.reset_password(
      update_administrateur_params[:reset_password_token],
      update_administrateur_params[:password]
    )

    if administrateur && administrateur.errors.empty?
      sign_in(administrateur, scope: :administrateur)
      flash.notice = "Mot de passe enregistré"
      redirect_to admin_procedures_path
    else
      flash.alert = administrateur.errors.full_messages
      redirect_to admin_activate_path(token: update_administrateur_params[:reset_password_token])
    end
  end

  private

  def update_administrateur_params
    params.require(:administrateur).permit(:reset_password_token, :password)
  end
end
