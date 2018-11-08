module Manager
  class GestionnairesController < Manager::ApplicationController
    def reinvite
      gestionnaire = Gestionnaire.find(params[:id])
      gestionnaire.invite!
      flash[:notice] = "Instructeur réinvité."
      redirect_to manager_gestionnaire_path(gestionnaire)
    end

    def enable_feature
      gestionnaire = Gestionnaire.find(params[:id])

      params[:features].each do |key, enable|
        if enable
          gestionnaire.enable_feature(key.to_sym)
        else
          gestionnaire.disable_feature(key.to_sym)
        end
      end

      head :ok
    end
  end
end
