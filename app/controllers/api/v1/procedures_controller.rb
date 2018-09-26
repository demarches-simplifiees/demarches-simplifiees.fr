class API::V1::ProceduresController < APIController
  before_action :fetch_procedure_and_check_token

  resource_description do
    description AUTHENTICATION_TOKEN_DESCRIPTION
  end

  api :GET, '/procedures/:id', 'Informations concernant une démarche'
  param :id, Integer, desc: "L'identifiant de la démarche", required: true
  error code: 401, desc: "Non authorisé"
  error code: 404, desc: "Démarche inconnue"

  def show
    render json: { procedure: ProcedureSerializer.new(@procedure.decorate).as_json }
  end

  private

  def fetch_procedure_and_check_token
    @procedure = Procedure.includes(:administrateur).find(params[:id])

    if !valid_token_for_administrateur?(@procedure.administrateur)
      render json: {}, status: :unauthorized
    end

  rescue ActiveRecord::RecordNotFound
    render json: {}, status: :not_found
  end
end
