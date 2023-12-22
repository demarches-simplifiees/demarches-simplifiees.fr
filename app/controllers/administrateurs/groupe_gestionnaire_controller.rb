module Administrateurs
  class GroupeGestionnaireController < AdministrateurController
    before_action :retrieve_groupe_gestionnaire, only: [:show, :administrateurs, :gestionnaires]

    def show
    end

    def administrateurs
    end

    def gestionnaires
    end

    private

    def retrieve_groupe_gestionnaire
      id = current_administrateur.groupe_gestionnaire_id
      @groupe_gestionnaire = GroupeGestionnaire.find(id)

      Sentry.configure_scope do |scope|
        scope.set_tags(groupe_gestionnaire: @groupe_gestionnaire.id)
      end
    rescue ActiveRecord::RecordNotFound
      flash.alert = 'Groupe inexistant'
      redirect_to admin_procedures_path, status: 404
    end
  end
end
