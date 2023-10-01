module Manager
  class GestionnairesController < Manager::ApplicationController
    def delete
      gestionnaire = Gestionnaire.find(params[:id])

      if !gestionnaire.can_be_deleted?
        fail "Impossible de supprimer ce gestionnaire car il est gestionnaire d'un groupe racine"
      end
      gestionnaire.destroy!

      logger.info("Le gestionnaire #{gestionnaire.id} est supprimé par #{current_super_admin.id}")
      flash[:notice] = "Le gestionnaire #{gestionnaire.id} est supprimé"

      redirect_to manager_gestionnaires_path
    end
  end
end
