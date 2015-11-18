class Admin::TypesDeChampController < AdminController

  before_action :retrieve_procedure

  def destroy
    @procedure.types_de_champ.destroy(params[:id])
    render 'show', format: :js
  rescue ActiveRecord::RecordNotFound
    render json: { message: 'Champ not found' }, status: 404
  end

  def show
  end

  def update
    @procedure.update_attributes(update_params)
    render 'show', format: :js
  end

  def update_params
    params.require(:procedure).permit(types_de_champ_attributes: [:libelle, :description, :order_place, :type_champ, :id])
  end

  def move_up
    index = params[:index].to_i
    if @procedure.types_de_champ.count < 2 || index < 1
      render json: {}, status: 400
    else
      types_de_champ_to_move_down = @procedure.types_de_champ_ordered[index - 1]
      types_de_champ_to_move_up = @procedure.types_de_champ_ordered[index]
      types_de_champ_to_move_down.update_attributes(order_place: index)
      types_de_champ_to_move_up.update_attributes(order_place: index - 1)

      render 'show', format: :js
    end
  end

  private

  def retrieve_procedure
    @procedure = Procedure.find(params[:procedure_id])
  rescue ActiveRecord::RecordNotFound
    render json: { message: 'Procedure not found' }, status: 404
  end
end