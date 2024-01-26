module Gestionnaires
  class GroupeGestionnairesController < GestionnaireController
    def index
      @groupe_gestionnaires = groupe_gestionnaires
    end

    private

    def groupe_gestionnaires
      groupe_gestionnaire_ids = current_gestionnaire.groupe_gestionnaire_ids
      GroupeGestionnaire.where(id: groupe_gestionnaire_ids.compact.uniq)
    end
  end
end
