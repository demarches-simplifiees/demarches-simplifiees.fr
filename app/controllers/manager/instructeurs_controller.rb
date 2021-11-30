module Manager
  class InstructeursController < Manager::ApplicationController
    # Temporary code: synchronize Flipper's instructeur_bypass_email_login_token
    # when Instructeur.bypass_email_login_token is modified.
    #
    # This will be removed when the migration of this feature flag out of Flipper will be complete.
    def update
      super

      instructeur = requested_resource
      saved_successfully = !requested_resource.changed?
      if saved_successfully
        if instructeur.bypass_email_login_token
          Flipper.enable_actor(:instructeur_bypass_email_login_token, instructeur.user)
        else
          Flipper.disable_actor(:instructeur_bypass_email_login_token, instructeur.user)
        end
      end
    end

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
