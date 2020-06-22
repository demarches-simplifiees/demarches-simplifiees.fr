module Instructeurs
  class RechercheController < InstructeurController
    def index
      @search_terms = params[:q]
      @dossiers = DossierSearchService.matching_dossiers_for_instructeur(@search_terms, current_instructeur)
      @followed_dossiers_id = current_instructeur
        .followed_dossiers
        .where(groupe_instructeur_id: @dossiers.pluck(:groupe_instructeur_id))
        .pluck(:id)
    end
  end
end
