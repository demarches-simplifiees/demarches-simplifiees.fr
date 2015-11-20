class Admin::PiecesJustificativesController < AdminController
  before_action :retrieve_procedure

  def show
  end

  def update
    @procedure.update_attributes(update_params)
    render 'show', format: :js
  end

  def update_params
    params
      .require(:procedure)
      .permit(types_de_piece_justificative_attributes: [:libelle, :description, :id])
  end


  def retrieve_procedure
    @procedure = current_administrateur.procedures.find(params[:procedure_id])
  rescue ActiveRecord::RecordNotFound
    render json: { message: 'Procedure not found' }, status: 404
  end
end