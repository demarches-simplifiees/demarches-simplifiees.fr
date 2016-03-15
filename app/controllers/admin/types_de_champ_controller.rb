class Admin::TypesDeChampController < AdminController
  before_action :retrieve_procedure
  before_action :procedure_locked?
  
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
    flash.now.notice = 'Modifications sauvegardées'
    render 'show', format: :js
  end

  def update_params
    params.require(:procedure).permit(types_de_champ_attributes: [:libelle, :description, :order_place, :type_champ, :id, :mandatory])
  end

  def move_up
    index = params[:index].to_i - 1
    if @procedure.switch_types_de_champ index
      render 'show', format: :js
    else
      render json: {}, status: 400
    end
  end

  def move_down
    if @procedure.switch_types_de_champ params[:index].to_i
      render 'show', format: :js
    else
      render json: {}, status: 400
    end
  end
end