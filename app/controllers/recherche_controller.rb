class RechercheController < ApplicationController
  before_action :authenticate_logged_user!
  ITEMS_PER_PAGE = 25
  PROJECTIONS = [
    { "table" => 'procedure', "column" => 'libelle' },
    { "table" => 'user', "column" => 'email' },
    { "table" => 'procedure', "column" => 'procedure_id' }
  ]

  def index
    @search_terms = search_terms
    matching_dossiers_ids = []
    instructeur_dossiers_ids = []
    expert_dossiers_ids = []

    if instructeur_signed_in?
      instructeur_dossiers_ids.concat(current_instructeur.dossiers.ids)
      @followed_dossiers_id = current_instructeur.followed_dossiers.where(id: instructeur_dossiers_ids).ids

      if instructeur_dossiers_ids.present?
        matching_dossiers_ids.concat(DossierSearchService.matching_dossiers(instructeur_dossiers_ids, @search_terms, true))
      end
    end

    if expert_signed_in?
      @dossier_avis_ids_h = current_expert.avis.pluck(:dossier_id, :id).to_h
      expert_dossiers_ids.concat(@dossier_avis_ids_h.keys)

      if expert_dossiers_ids.present?
        matching_dossiers_ids.concat(DossierSearchService.matching_dossiers(expert_dossiers_ids, @search_terms))
      end
    end

    @paginated_ids = Kaminari
      .paginate_array(matching_dossiers_ids.uniq)
      .page(page)
      .per(ITEMS_PER_PAGE)

    @dossiers_count = matching_dossiers_ids.count

    @projected_dossiers = DossierProjectionService.project(@paginated_ids, PROJECTIONS)
  end

  private

  def page
    params[:page].presence || 1
  end

  def search_terms
    params[:q]
  end
end
