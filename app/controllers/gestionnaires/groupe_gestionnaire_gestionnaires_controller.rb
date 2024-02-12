module Gestionnaires
  class GroupeGestionnaireGestionnairesController < GestionnaireController
    before_action :retrieve_groupe_gestionnaire, except: [:new]

    def index
    end

    def create
      gestionnaires, flash[:alert], flash[:notice] = @groupe_gestionnaire.add_gestionnaires(emails: [params.require(:gestionnaire)[:email]], current_user: current_gestionnaire)
      @gestionnaire = gestionnaires[0]
    end

    def destroy
      @gestionnaire, flash[:alert], flash[:notice] = @groupe_gestionnaire.remove(params[:id], current_gestionnaire)
    end
  end
end
