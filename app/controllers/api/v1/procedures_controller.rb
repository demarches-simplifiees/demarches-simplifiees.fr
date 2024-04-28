# frozen_string_literal: true

class API::V1::ProceduresController < APIController
  before_action :check_api_token
  before_action :fetch_procedure

  def show
    render json: { procedure: ProcedureSerializer.new(@procedure).as_json }
  end

  private

  def fetch_procedure
    @procedure = @api_token.procedures.for_api.find(params[:id])

  rescue ActiveRecord::RecordNotFound
    render json: {}, status: :not_found
  end
end
