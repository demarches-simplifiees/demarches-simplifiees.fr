class API::V1::ProceduresController < APIController
  def show
    @procedure = current_administrateur.procedures.find(params[:id]).decorate

    render json: @procedure
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error(e.message)
    render json: {}, status: 404
  end

end
