class Admin::TypesDeChampPrivateController < AdminController
  before_action :retrieve_procedure
  before_action :procedure_locked?
  before_action :reset_procedure, only: [:update, :destroy, :move_up, :move_down]

  def destroy
    @procedure.types_de_champ_private.destroy(params[:id])
    setup_type_de_champ_service
    render 'admin/types_de_champ/show', format: :js
  rescue ActiveRecord::RecordNotFound
    render json: { message: 'Champ not found' }, status: 404
  end

  def show
    setup_type_de_champ_service
    render 'admin/types_de_champ/show'
  end

  def update
    setup_type_de_champ_service
    if @procedure.update(@type_de_champ_service.create_update_procedure_params(params))
      flash.now.notice = 'Modifications sauvegardées'
    else
      flash.now.alert = @procedure.errors.full_messages.join(', ')
    end
    render 'admin/types_de_champ/show', format: :js
  end

  def move_up
    index = params[:index].to_i - 1
    if @procedure.switch_types_de_champ_private(index)
      setup_type_de_champ_service
      render 'admin/types_de_champ/show', format: :js
    else
      render json: {}, status: 400
    end
  end

  def move_down
    if @procedure.switch_types_de_champ_private(params[:index].to_i)
      setup_type_de_champ_service
      render 'admin/types_de_champ/show', format: :js
    else
      render json: {}, status: 400
    end
  end

  private

  def setup_type_de_champ_service
    @type_de_champ_service = TypesDeChampService.new(@procedure, true)
  end
end
