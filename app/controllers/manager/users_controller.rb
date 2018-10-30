module Manager
  class UsersController < Manager::ApplicationController
    def resend_confirmation_instructions
      user = User.find(params[:id])
      user.resend_confirmation_instructions
      flash[:notice] = "L'email d'activation de votre compte a été renvoyé."
      redirect_to manager_user_path(user)
    end
  end
end
