class API::V1::DossiersController < APIController
  before_action :fetch_procedure_and_check_token

  DEFAULT_PAGE_SIZE = 100
  MAX_PAGE_SIZE = 1000
  ORDER_DIRECTIONS = { 'asc' => :asc, 'desc' => :desc }

  def index
    dossiers = @dossiers.page(params[:page]).per(per_page)

    render json: { dossiers: dossiers.map { |dossier| DossiersSerializer.new(dossier) }, pagination: pagination(dossiers) }, status: 200
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: 404
  end

  def show
    dossier = @dossiers.for_api.find(params[:id])

    respond_to do |format|
      format.json { render json: { dossier: DossierSerializer.new(dossier).as_json }, status: 200 }
    end
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: 404
  end

  private

  def pagination(dossiers)
    {
      page: dossiers.current_page,
      resultats_par_page: dossiers.limit_value,
      nombre_de_page: dossiers.total_pages
    }
  end

  def per_page # inherited value from will_paginate
    resultats_par_page = params[:resultats_par_page]&.to_i
    if resultats_par_page && resultats_par_page > 0
      [resultats_par_page, MAX_PAGE_SIZE].min
    else
      DEFAULT_PAGE_SIZE
    end
  end

  def fetch_procedure_and_check_token
    @procedure = Procedure.for_api.find(params[:procedure_id])

    administrateur = find_administrateur_for_token(@procedure)
    if administrateur
      Current.administrateur = administrateur
    else
      render json: {}, status: :unauthorized
    end

    order = ORDER_DIRECTIONS.fetch(params[:order], :asc)
    @dossiers = @procedure.dossiers.state_not_brouillon.order_by_created_at(order)

  rescue ActiveRecord::RecordNotFound
    render json: {}, status: :not_found
  end
end
