class API::V1::DossiersController < APIController
  before_action :fetch_procedure_and_check_token

  DEFAULT_PAGE_SIZE = 100

  def index
    dossiers = @procedure.dossiers.state_not_brouillon.page(params[:page]).per(per_page)

    render json: { dossiers: dossiers.map{ |dossier| DossiersSerializer.new(dossier) }, pagination: pagination(dossiers) }, status: 200
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: 404
  end

  def show
    dossier = @procedure.dossiers.find(params[:id])

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
    [params[:resultats_par_page]&.to_i || DEFAULT_PAGE_SIZE, 1000].min
  end

  def fetch_procedure_and_check_token
    @procedure = Procedure.includes(:administrateur).find(params[:procedure_id])

    if !valid_token_for_administrateur?(@procedure.administrateur)
      render json: {}, status: :unauthorized
    end

  rescue ActiveRecord::RecordNotFound
    render json: {}, status: :not_found
  end
end
