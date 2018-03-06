class Admin::TypesDeChampPrivateController < AdminController
  before_action :retrieve_procedure
  before_action :procedure_locked?

  def destroy
    @procedure.types_de_champ_private.destroy(params[:id])
    create_facade
    render 'admin/types_de_champ/show', format: :js
  rescue ActiveRecord::RecordNotFound
    render json: { message: 'Champ not found' }, status: 404
  end

  def show
    create_facade
    render 'admin/types_de_champ/show'
  end

  def update
    @procedure.update_attributes(TypesDeChampService.create_update_procedure_params params, true)
    create_facade
    flash.now.notice = 'Modifications sauvegardées'
    render 'admin/types_de_champ/show', format: :js
  end

  def move_up
    index = params[:index].to_i - 1
    if @procedure.switch_types_de_champ_private index
      create_facade
      render 'admin/types_de_champ/show', format: :js
    else
      render json: {}, status: 400
    end
  end

  def move_down
    if @procedure.switch_types_de_champ_private params[:index].to_i
      create_facade
      render 'admin/types_de_champ/show', format: :js
    else
      render json: {}, status: 400
    end
  end

  private

  def create_facade
    @types_de_champ_facade = AdminTypesDeChampFacades.new true, @procedure
  end
end
