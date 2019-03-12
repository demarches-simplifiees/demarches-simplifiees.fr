class API::V1::ProceduresController < APIController
  before_action :fetch_procedure_and_check_token

  def show
    render json: { procedure: ProcedureSerializer.new(@procedure).as_json }
  end

  private

  def fetch_procedure_and_check_token
    @procedure = Procedure.for_api.find(params[:id])

    administrateur = find_administrateur_for_token(@procedure)
    if administrateur
      Current.administrateur = administrateur
    else
      render json: {}, status: :unauthorized
    end

  rescue ActiveRecord::RecordNotFound
    render json: {}, status: :not_found
  end
end
