class API::V1::ProceduresController < APIController

  swagger_controller :procedures, "Procédure API"

  swagger_api :show do
    summary "Récupérer les informations d'une procédure"
    param :path, :id, :integer, :required
    param :path, :token, :string, :required
    response :ok, "Success", :Procedure
    response :unauthorized
    response :not_found
  end

  def show
    @procedure = current_administrateur.procedures.find(params[:id]).decorate

    render json: @procedure
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error(e.message)
    render json: {}, status: 404
  end

end
