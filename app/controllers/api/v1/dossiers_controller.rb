class API::V1::DossiersController < APIController

  api :GET, '/procedures/:procedure_id/dossiers/', 'Liste de tous les dossiers d\'une procédure'
  param :procedure_id, Integer, desc: "L'identifiant de la procédure", required: true
  param :token, String, desc: "Token administrateur", required: true
  error code: 401, desc: "Non authorisé"
  error code: 404, desc: "Procédure inconnue"

  description <<-EOS
  Plop
  EOS

  meta champs: {

       }

  def index
    procedure = current_administrateur.procedures.find(params[:procedure_id])
    dossiers = procedure.dossiers.where.not(state: :draft).paginate(page: params[:page])
    render json: dossiers, each_serializer: DossiersSerializer, meta: pagination(dossiers), meta_key: 'pagination', status: 200
  rescue ActiveRecord::RecordNotFound => e
    render json: {}, status: 404
  end

  api :GET, '/procedures/:procedure_id/dossiers/:id', 'Informations du dossier d\'une procédure'
  param :procedure_id, Integer, desc: "L'identifiant de la procédure", required: true
  param :dossier_id, Integer, desc: "L'identifiant du dossier", required: true
  param :token, String, desc: "Token administrateur", required: true
  error code: 401, desc: "Non authorisé"
  error code: 404, desc: "Procédure ou dossier inconnu"

  description <<-EOS
  Plop
  EOS

  meta champs: {

       }

  def show
    procedure = current_administrateur.procedures.find(params[:procedure_id])
    dossier = procedure.dossiers.find(params[:id])
    respond_to do |format|
      format.json { render json: dossier, status: 200 }
      format.csv  { render  csv: dossier, status: 200 }
    end
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