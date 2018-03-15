class API::V1::DossiersController < APIController
  DEFAULT_PAGE_SIZE = 100

  resource_description do
    description AUTHENTICATION_TOKEN_DESCRIPTION
  end

  api :GET, '/procedures/:procedure_id/dossiers/', 'Liste de tous les dossiers d\'une procédure'
  param :procedure_id, Integer, desc: "L'identifiant de la procédure", required: true
  param :page, String, desc: "Numéro de la page", required: false
  param :resultats_par_page, String, desc: "Nombre de résultats par page (#{DEFAULT_PAGE_SIZE} par défaut, maximum 1 000)", required: false
  error code: 401, desc: "Non authorisé"
  error code: 404, desc: "Procédure inconnue"

  def index
    procedure = administrateur.procedures.find(params[:procedure_id])
    dossiers = procedure.dossiers.state_not_brouillon.page(params[:page]).per(per_page)

    render json: { dossiers: dossiers.map{ |dossier| DossiersSerializer.new(dossier) }, pagination: pagination(dossiers) }, status: 200
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: 404
  end

  api :GET, '/procedures/:procedure_id/dossiers/:id', 'Informations du dossier d\'une procédure'
  param :procedure_id, Integer, desc: "L'identifiant de la procédure", required: true
  param :dossier_id, Integer, desc: "L'identifiant du dossier", required: true
  error code: 401, desc: "Non authorisé"
  error code: 404, desc: "Procédure ou dossier inconnu"

  def show
    procedure = administrateur.procedures.find(params[:procedure_id])
    dossier = procedure.dossiers.find(params[:id])

    respond_to do |format|
      format.json { render json: { dossier: DossierSerializer.new(dossier).as_json }, status: 200 }
    end
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: 404
  end

  def pagination(dossiers)
    {
      page: dossiers.current_page,
      resultats_par_page: dossiers.limit_value,
      nombre_de_page: dossiers.total_pages
    }
  end

  def per_page # inherited value from will_paginate
    [params[:resultats_par_page] || DEFAULT_PAGE_SIZE, 1000].min
  end
end
