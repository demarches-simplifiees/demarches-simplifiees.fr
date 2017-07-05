module NewGestionnaire
  class ProceduresController < GestionnaireController
    before_action :ensure_ownership!

    private

    def procedure
      Procedure.find(params[:procedure_id])
    end

    def ensure_ownership!
      if !procedure.gestionnaires.include?(current_gestionnaire)
        flash[:alert] = "Vous n'avez pas accès à cette procédure"
        redirect_to root_path
      end
    end
  end
end
