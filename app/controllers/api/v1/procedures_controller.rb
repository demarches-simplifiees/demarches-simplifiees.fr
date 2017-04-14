class API::V1::ProceduresController < APIController
  api :GET, '/procedures/:id', 'Informations concernant une procédure'
  param :id, Integer, desc: "L'identifiant de la procédure", required: true
  param :token, String, desc: "Token administrateur", required: true
  error code: 401, desc: "Non authorisé"
  error code: 404, desc: "Procédure inconnue"

  meta champs: {

       }

  def show
    procedure = current_administrateur.procedures.find(params[:id]).decorate

    render json: {procedure: ProcedureSerializer.new(procedure).as_json}
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error(e.message)
    render json: {}, status: 404
  end

end
