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

    # if an instructor search for a dossier which is in his procedures but not available to his intructor group
    # we want to display an alert in view

    # to make it simpler we only do it if the @search_terms is an id
    if DossierSearchService.id_compatible?(@search_terms)
      dossier_instructeur_searched_for = Dossier.find_by(id: @search_terms)

      if dossier_instructeur_searched_for.present? &&
          !@instructeur_dossiers_ids.include?(dossier_instructeur_searched_for.id) &&
          current_instructeur&.procedures&.include?(dossier_instructeur_searched_for.procedure)

        @dossier_not_in_instructor_group = dossier_instructeur_searched_for
      end
    end
  end

  private

  def page
    params[:page].presence || 1
  end

  def search_terms
    params[:q]
  end
end
