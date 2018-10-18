module NewGestionnaire
  class RechercheController < GestionnaireController
    def index
      @search_terms = params[:q]
      @dossiers = DossierSearchService.matching_dossiers_for_gestionnaire(@search_terms, current_gestionnaire)
      @followed_dossiers_id = current_gestionnaire
        .followed_dossiers
        .where(procedure_id: @dossiers.pluck(:procedure_id))
        .pluck(:id)
    end
  end
end
