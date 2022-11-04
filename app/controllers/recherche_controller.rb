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

    @instructeur_dossiers_ids = DossierSearchService
      .matching_dossiers(current_instructeur&.dossiers, @search_terms, with_annotation: true)

    expert_dossier_ids = DossierSearchService
      .matching_dossiers(current_expert&.dossiers, @search_terms)

    matching_dossiers_ids = (@instructeur_dossiers_ids + expert_dossier_ids).uniq

    @paginated_ids = Kaminari
      .paginate_array(matching_dossiers_ids)
      .page(page)
      .per(ITEMS_PER_PAGE)

    @projected_dossiers = DossierProjectionService.project(@paginated_ids, PROJECTIONS)

    @dossiers_count = matching_dossiers_ids.count
    @followed_dossiers_id = current_instructeur&.followed_dossiers&.where(id: @paginated_ids)&.ids || []
    @dossier_avis_ids_h = current_expert&.avis&.where(dossier_id: @paginated_ids)&.pluck(:dossier_id, :id).to_h || {}

    # we want to retrieve dossiers that are not accessible to the instructor because he is not in the instructor group
    # to display an alert in the view
    instructeur_procedure_dossiers_ids = DossierSearchService
      .matching_dossiers(Dossier.joins(:procedure).where(procedure: {id: current_instructeur&.procedures&.ids}), @search_terms, with_annotation: true)

    not_in_instructor_group_dossiers_ids = instructeur_procedure_dossiers_ids - matching_dossiers_ids

    @not_in_instructor_group_dossiers = Dossier.where(id: not_in_instructor_group_dossiers_ids)
  end

  private

  def page
    params[:page].presence || 1
  end

  def search_terms
    params[:q]
  end
end
