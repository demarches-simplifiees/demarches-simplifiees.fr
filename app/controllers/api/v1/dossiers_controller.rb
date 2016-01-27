class API::V1::DossiersController < APIController

  def index
    procedure = current_administrateur.procedures.find(params[:procedure_id])
    dossiers = procedure.dossiers.paginate(page: params[:page])
    render json: dossiers, each_serializer: DossiersSerializer, meta: pagination(dossiers), meta_key: 'pagination', status: 200
  rescue ActiveRecord::RecordNotFound => e
    render json: {}, status: 404
  end

  def show
    procedure = current_administrateur.procedures.find(params[:procedure_id])
    dossier = procedure.dossiers.find(params[:id])
    render json: dossier, status: 200
  rescue ActiveRecord::RecordNotFound => e
    render json: {}, status: 404
  end

  def pagination(dossiers)
    {
      page: dossiers.current_page,
      resultats_par_page: dossiers.per_page,
      nombre_de_page: dossiers.total_pages
    }
  end
end