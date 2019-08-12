module Manager
  class InstructeursController < Manager::ApplicationController
    def reinvite
      instructeur = Instructeur.find(params[:id])
      instructeur.invite!
      flash[:notice] = "Instructeur réinvité."
      redirect_to manager_instructeur_path(instructeur)
    end

    def enable_feature
      instructeur = Instructeur.find(params[:id])

      params[:features].each do |key, enable|
        if enable
          instructeur.enable_feature(key.to_sym)
        else
          instructeur.disable_feature(key.to_sym)
        end
      end

      head :ok
    end
  end
end
