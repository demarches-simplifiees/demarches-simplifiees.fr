module NewGestionnaire
  class RechercheController < GestionnaireController
    def index
      @search_terms = params[:q]
      @dossiers = DossierSearchService.matching_dossiers_for_gestionnaire(@search_terms)
    end
  end
end
