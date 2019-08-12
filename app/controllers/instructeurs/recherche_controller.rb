module Instructeurs
  class RechercheController < InstructeurController
    def index
      @search_terms = params[:q]
      @dossiers = DossierSearchService.matching_dossiers_for_instructeur(@search_terms, current_instructeur)
      @followed_dossiers_id = current_instructeur
        .followed_dossiers
        .where(procedure_id: @dossiers.pluck(:procedure_id))
        .pluck(:id)
    end
  end
end
