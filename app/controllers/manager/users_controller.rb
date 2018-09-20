module Manager
  class UsersController < Manager::ApplicationController
    def resend_confirmation_instructions
      user = User.find(params[:id])
      user.resend_confirmation_instructions
      flash[:notice] = "L'email d'activation de votre compte a été renvoyé."
      redirect_to manager_user_path(user)
    end

    def confirm
      user = User.find(params[:id])
      user.confirm
      flash[:notice] = "L’adresse email de l’utilisateur a été marquée comme activée."
      redirect_to manager_user_path(user)
    end
  end
end
