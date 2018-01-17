module Manager
  class AdministrateursController < Manager::ApplicationController
    def create
      administrateur = current_administration.invite_admin(create_administrateur_params[:email])

      if administrateur.errors.empty?
        flash.notice = "Administrateur créé"
      else
        flash.alert = administrateur.errors.full_messages
      end

      redirect_to manager_administrateurs_path
    end

    private

    def create_administrateur_params
      params.require(:administrateur).permit(:email)
    end
  end
end
