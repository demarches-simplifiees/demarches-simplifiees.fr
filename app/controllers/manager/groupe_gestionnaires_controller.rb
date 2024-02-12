module Manager
  class GroupeGestionnairesController < Manager::ApplicationController
    def add_gestionnaire
      _gestionnaires, flash[:alert], flash[:notice] = groupe_gestionnaire.add_gestionnaires(emails: (params['emails'].presence || '').split(','), current_user: current_super_admin)

      redirect_to manager_groupe_gestionnaire_path(groupe_gestionnaire)
    end

    def remove_gestionnaire
      _gestionnaire, flash[:alert], flash[:notice] = groupe_gestionnaire.remove(gestionnaire_id, current_super_admin)

      redirect_to manager_groupe_gestionnaire_path(groupe_gestionnaire)
    end

    private

    def groupe_gestionnaire
      @groupe_gestionnaire ||= GroupeGestionnaire.find(params[:id])
    end

    def gestionnaire_id
      params[:gestionnaire][:id]
    end
  end
end
