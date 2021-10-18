module Manager
  class UsersController < Manager::ApplicationController
    def update
      user = User.find(params[:id])
      preexisting_user = User.find_by(email: targeted_email)

      elsif preexisting_user.nil?
      if preexisting_user.nil?
        user.skip_reconfirmation!
        user.update(email: targeted_email)

        if (user.valid?)
          flash[:notice] = "L'email a été modifié en « #{targeted_email} » sans notification ni validation par email."
        else
          flash[:error] = user.errors.full_messages.to_sentence
        end
      else
        user.dossiers.update_all(user_id: preexisting_user.id)

        [
          [user.instructeur, preexisting_user.instructeur],
          [user.expert, preexisting_user.expert],
          [user.administrateur, preexisting_user.administrateur]
        ].each do |old_role, preexisting_role|
          if preexisting_role.nil?
            old_role&.update(user: preexisting_user)
          else
            preexisting_role.merge(old_role)
          end
        end

        flash[:notice] = "Le compte « #{targeted_email} » a absorbé le compte « #{user.email} »."
      end

      redirect_to edit_manager_user_path(user)
    end

    def resend_confirmation_instructions
      user = User.find(params[:id])
      user.resend_confirmation_instructions
      flash[:notice] = "L'email d’activation de votre compte a été renvoyé."
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
      user.delete_and_keep_track_dossiers(current_super_admin)

      logger.info("L'utilisateur #{user.id} est supprimé par #{current_super_admin.id}")
      flash[:notice] = "L'utilisateur #{user.id} est supprimé"

      redirect_to manager_users_path
    end

    def emails
      @user = User.find(params[:id])

      email_services = [
        Mailjet::API.new,
        Sendinblue::API.new
      ]

      @sent_mails = email_services
        .filter(&:properly_configured?)
        .map { |api| api.sent_mails(@user.email) }
        .flatten
        .sort_by(&:delivered_at)
        .reverse
    end

    def unblock_email
      @user = User.find(params[:user_id])
      if Sendinblue::API.new.unblock_user(@user.email)
        flash.notice = "L'adresse email a été débloquée auprès de Sendinblue"
      else
        flash.alert = "Impossible de débloquer cette addresse email auprès de Sendinblue"
      end
      redirect_to emails_manager_user_path(@user)
    end

    private

    def targeted_email
      params[:user][:email]
    end
  end
end
