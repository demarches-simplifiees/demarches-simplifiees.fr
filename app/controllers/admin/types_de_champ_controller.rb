class Admin::TypesDeChampController < AdminController

  before_action :retrieve_procedure

  def destroy
    @procedure.types_de_champ.destroy(params[:id])
    render json: { message: 'deleted' }, status: 200
  rescue ActiveRecord::RecordNotFound
    render json: { message: 'Champ not found' }, status: 404
  end

  def show
  end

  def update
    @procedure.update_attributes(update_params)
    respond_to do |format|
      format.js
    end
  end

  def update_params
    params.require(:procedure).permit(types_de_champ_attributes: [:libelle, :description, :order_place, :type_champ, :id])
  end

  private

  def retrieve_procedure
    @procedure = Procedure.find(params[:procedure_id])
  rescue ActiveRecord::RecordNotFound
    render json: { message: 'Procedure not found' }, status: 404
  end
end