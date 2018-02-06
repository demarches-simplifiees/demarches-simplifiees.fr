module NewGestionnaire
  class RechercheController < GestionnaireController
    def index
      @search_terms = params[:q]

      # exact id match?
      id = @search_terms.to_i
      if id != 0 && id_compatible?(id) # Sometimes gestionnaire is searching dossiers with a big number (ex: SIRET), ActiveRecord can't deal with them and throws ActiveModel::RangeError. id_compatible? prevents this.
        @dossiers = dossiers_by_id(id)
      end

      if @dossiers.nil?
        @dossiers = Dossier.none
      end

      # full text search
      if @dossiers.empty?
        @dossiers = Search.new(
          gestionnaire: current_gestionnaire,
          query: @search_terms,
          page: params[:page]
        ).results
      end
    end

    private

    def dossiers_by_id(id)
      dossiers = current_gestionnaire.dossiers.where(id: id) +
        current_gestionnaire.dossiers_from_avis.where(id: id)
      dossiers.uniq
    end

    def id_compatible?(number)
      begin
        ActiveRecord::Type::Integer.new.serialize(number)
        true
      rescue ActiveModel::RangeError
        false
      end
    end
  end
end
