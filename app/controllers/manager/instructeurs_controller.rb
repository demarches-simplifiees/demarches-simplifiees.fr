module Manager
  class InstructeursController < Manager::ApplicationController
    def reinvite
      instructeur = Instructeur.find(params[:id])
      instructeur.user.invite!
      flash[:notice] = "Instructeur réinvité."
      redirect_to manager_instructeur_path(instructeur)
    end
  end
end
