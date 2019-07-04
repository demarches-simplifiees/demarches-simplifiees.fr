module Manager
  class AdministrateursController < Manager::ApplicationController
    def create
      administrateur = current_administration.invite_admin(create_administrateur_params[:email])

      if administrateur.errors.empty?
        flash.notice = "Administrateur créé"
        redirect_to manager_administrateurs_path
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, administrateur)
        }
      end
    end

    def reinvite
      Administrateur.find_inactive_by_id(params[:id]).invite!(current_administration.id)
      flash.notice = "Invitation renvoyée"
      redirect_to manager_administrateur_path(params[:id])
    end

    def delete
      administrateur = Administrateur.find(params[:id])

      if !administrateur.can_be_deleted?
        fail "Impossible de supprimer cet administrateur car il a des dossiers ou des procédures"
      end
      administrateur.dossiers.each(&:delete_and_keep_track)
      administrateur.destroy

      logger.info("L'administrateur #{administrateur.id} est supprimé par #{current_administration.id}")
      flash[:notice] = "L'administrateur #{administrateur.id} est supprimé"

      redirect_to manager_administrateurs_path
    end

    private

    def create_administrateur_params
      params.require(:administrateur).permit(:email)
    end
  end
end
