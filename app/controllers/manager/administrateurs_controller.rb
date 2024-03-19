module Manager
  class AdministrateursController < Manager::ApplicationController
    def create
      administrateur = current_super_admin.invite_admin(create_administrateur_params[:email])

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
      Administrateur.find_inactive_by_id(params[:id]).user.invite_administrateur!
      flash.notice = "Invitation renvoyée"
      redirect_to manager_administrateur_path(params[:id])
    end

    def delete
      administrateur = Administrateur.find(params[:id])

      result = AdministrateurDeletionService.new(current_super_admin, administrateur).call

      case result
      in Dry::Monads::Result::Success
        logger.info("L'administrateur #{administrateur.id} est supprimé par #{current_super_admin.id}")
        flash[:notice] = "L'administrateur #{administrateur.id} est supprimé"
      in Dry::Monads::Result::Failure(reason)
        flash[:alert] = I18n.t(reason, scope: "manager.administrateurs.delete")
      end

      redirect_to manager_administrateurs_path
    end

    private

    def create_administrateur_params
      params.require(:administrateur).permit(:email)
    end
  end
end
