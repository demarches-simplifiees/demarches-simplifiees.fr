module Gestionnaires
  class GroupeGestionnaireAdministrateursController < GestionnaireController
    before_action :retrieve_groupe_gestionnaire, except: [:new]

    def index
    end

    def create
      administrateurs, flash[:alert], flash[:notice] = @groupe_gestionnaire.add_administrateurs(emails: [params.require(:administrateur)[:email]], current_user: current_gestionnaire)
      @administrateur = administrateurs[0]
    end

    def destroy
      @administrateur, flash[:alert], flash[:notice] = @groupe_gestionnaire.remove_administrateur(params[:id], current_gestionnaire)
    end
  end
end
