module NewGestionnaire
  class RechercheController < GestionnaireController
    def index
      @search_terms = params[:q]

      # exact id match?
      if @search_terms.to_i != 0
        @dossiers = current_gestionnaire.dossiers.where(id: @search_terms.to_i)
      end

      @dossiers = Dossier.none if @dossiers.nil?

      # full text search
      if @dossiers.empty?
        @dossiers = Search.new(
            gestionnaire: current_gestionnaire,
            query: @search_terms,
            page: params[:page]
        ).results
      end
    end
  end
end
