module Manager
  class UsersController < Manager::ApplicationController
    def resend_confirmation_instructions
      user = User.find(params[:id])
      user.resend_confirmation_instructions
      flash[:notice] = "L'email d'activation de votre compte a été renvoyé."
      redirect_to manager_user_path(user)
    end

    def enable_feature
      user = User.find(params[:id])

      params[:features].each do |key, enable|
        if enable
          Flipper.enable_actor(key.to_sym, user)
        else
          Flipper.disable_actor(key.to_sym, user)
        end
      end

      head :ok
    end

    def delete
      user = User.find(params[:id])
      if !user.can_be_deleted?
        fail "Impossible de supprimer cet utilisateur car il a des dossiers en instruction"
      end
      user.delete_and_keep_track_dossiers(current_administration)

      logger.info("L'utilisateur #{user.id} est supprimé par #{current_administration.id}")
      flash[:notice] = "L'utilisateur #{user.id} est supprimé"

      redirect_to manager_users_path
    end
  end
end
