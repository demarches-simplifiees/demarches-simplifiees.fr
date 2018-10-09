class API::V1::ProceduresController < APIController
  before_action :fetch_procedure_and_check_token

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
