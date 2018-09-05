class API::V1::ProceduresController < APIController
  resource_description do
    description AUTHENTICATION_TOKEN_DESCRIPTION
  end

  api :GET, '/procedures/:id', 'Informations concernant une démarche'
  param :id, Integer, desc: "L'identifiant de la démarche", required: true
  error code: 401, desc: "Non authorisé"
  error code: 404, desc: "Démarche inconnue"

  def show
    procedure = administrateur.procedures.find(params[:id]).decorate

    render json: { procedure: ProcedureSerializer.new(procedure).as_json }
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error(e.message)
    render json: {}, status: 404
  end
end
