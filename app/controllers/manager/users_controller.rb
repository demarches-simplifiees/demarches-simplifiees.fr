module Manager
  class UsersController < Manager::ApplicationController
    def update
      user = User.find(params[:id])
      new_email = params[:user][:email]
      user.skip_reconfirmation!
      user.update(email: new_email)
      if (user.valid?)
        flash[:notice] = "L'email a été modifié en « #{new_email} » sans notification ni validation par email."
      else
        flash[:error] = "« #{new_email} » n'est pas une adresse valide."
      end
      redirect_to edit_manager_user_path(user)
    end

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
        fail "Impossible de supprimer cet utilisateur. Il a des dossiers en instruction ou il est administrateur."
      end
      user.delete_and_keep_track_dossiers(current_administration)

      logger.info("L'utilisateur #{user.id} est supprimé par #{current_administration.id}")
      flash[:notice] = "L'utilisateur #{user.id} est supprimé"

      redirect_to manager_users_path
    end
  end
end
