class Admin::PiecesJustificativesController < AdminController
  before_action :retrieve_procedure
  before_action :procedure_locked?

  def show
  end

  def update
    @procedure.update_attributes(update_params)
    flash.now.notice = 'Modifications sauvegardées'
    render 'show', format: :js
  end

  def destroy
    @procedure.types_de_piece_justificative.find(params[:id]).destroy

    render 'show', format: :js
  rescue ActiveRecord::RecordNotFound
    render json: { message: 'Type de piece justificative not found' }, status: 404
  end

  def update_params
    params
      .require(:procedure)
      .permit(types_de_piece_justificative_attributes: [:libelle, :description, :id, :order_place])
  end

  def move_up
    index = params[:index].to_i - 1
    if @procedure.switch_types_de_piece_justificative index
      render 'show', format: :js
    else
      render json: {}, status: 400
    end
  end

  def move_down
    if @procedure.switch_types_de_piece_justificative params[:index].to_i
      render 'show', format: :js
    else
      render json: {}, status: 400
    end
  end
end