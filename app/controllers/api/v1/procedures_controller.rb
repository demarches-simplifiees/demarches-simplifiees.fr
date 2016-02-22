class API::V1::ProceduresController < APIController

  swagger_controller :procedures, "Procédures"

  swagger_api :show do
    summary "Récupérer la liste de ses procédures."
    param :path, :id, :integer, "Procédure ID"
    param :query, :token, :integer, "Admin TOKEN"
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
