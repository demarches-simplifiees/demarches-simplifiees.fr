class Admin::TypesDeChampController < AdminController
  before_action :retrieve_procedure
  before_action :procedure_locked?
  before_action :reset_procedure, only: [:update, :destroy, :move_up, :move_down]

  def destroy
    @procedure.types_de_champ.destroy(params[:id])
    create_facade
    render 'show', format: :js
  rescue ActiveRecord::RecordNotFound
    render json: { message: 'Champ not found' }, status: 404
  end

  def show
    create_facade
  end

  def update
    if @procedure.update(TypesDeChampService.create_update_procedure_params params)
      flash.now.notice = 'Modifications sauvegardées'
    else
      flash.now.alert = @procedure.errors.full_messages.join(', ')
    end
    create_facade
    render 'show', format: :js
  end

  def move_up
    index = params[:index].to_i - 1
    if @procedure.switch_types_de_champ index
      create_facade
      render 'show', format: :js
    else
      render json: {}, status: 400
    end
  end

  def move_down
    if @procedure.switch_types_de_champ params[:index].to_i
      create_facade
      render 'show', format: :js
    else
      render json: {}, status: 400
    end
  end

  private

  def create_facade
    @types_de_champ_facade = AdminTypesDeChampFacades.new false, @procedure
  end
end
