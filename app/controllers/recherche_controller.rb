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

    @instructeur_dossiers_ids = current_instructeur&.dossiers&.ids || []
    matching_dossiers_ids = DossierSearchService.matching_dossiers(@instructeur_dossiers_ids, @search_terms, true)

    @dossier_avis_ids_h = current_expert&.avis&.pluck(:dossier_id, :id).to_h || {}
    expert_dossiers_ids = @dossier_avis_ids_h.keys
    matching_dossiers_ids.concat(DossierSearchService.matching_dossiers(expert_dossiers_ids, @search_terms))

    @dossiers_count = matching_dossiers_ids.count

    @paginated_ids = Kaminari
      .paginate_array(matching_dossiers_ids.uniq)
      .page(page)
      .per(ITEMS_PER_PAGE)

    @projected_dossiers = DossierProjectionService.project(@paginated_ids, PROJECTIONS)

    @followed_dossiers_id = current_instructeur&.followed_dossiers&.where(id: @paginated_ids)&.ids || []
  end

  private

  def page
    params[:page].presence || 1
  end

  def search_terms
    params[:q]
  end
end
