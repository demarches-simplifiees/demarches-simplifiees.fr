module Manager
  class InstructeursController < Manager::ApplicationController
    def reinvite
      instructeur = Instructeur.find(params[:id])
      instructeur.user.invite!
      flash[:notice] = "Instructeur réinvité."
      redirect_to manager_instructeur_path(instructeur)
    end

    def delete
      instructeur = Instructeur.find(params[:id])

      if !instructeur.can_be_deleted?
        fail "Impossible de supprimer cet instructeur car il est administrateur ou il est le seul instructeur sur une démarche"
      end
      instructeur.destroy!

      logger.info("L'instructeur #{instructeur.id} est supprimé par #{current_super_admin.id}")
      flash[:notice] = "L'instructeur #{instructeur.id} est supprimé"

      redirect_to manager_instructeurs_path
    end
  end
end
