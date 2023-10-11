module Gestionnaires
  class GroupeGestionnairesController < GestionnaireController
    before_action :retrieve_groupe_gestionnaire, only: [:show]

    def index
      @groupe_gestionnaires = groupe_gestionnaires
    end

    def show
    end

    private

    def groupe_gestionnaires
      groupe_gestionnaire_ids = current_gestionnaire.groupe_gestionnaire_ids
      GroupeGestionnaire.where(id: groupe_gestionnaire_ids.compact.uniq)
    end
  end
end
