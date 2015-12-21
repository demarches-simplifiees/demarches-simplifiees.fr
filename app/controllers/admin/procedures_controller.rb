class Admin::ProceduresController < AdminController

  before_action :retrieve_procedure, only: :edit

  def index
    @procedures = current_administrateur.procedures.where(archived: false)
                      .paginate(:page => params[:page]).decorate
    @page = 'active'
  end

  def archived
    @procedures = current_administrateur.procedures.where(archived: true)
                      .paginate(:page => params[:page]).decorate
    @page = 'archived'
  end

  def show
    informations

    @facade = AdminProceduresShowFacades.new @procedure
  end

  def edit
    informations
  end

  def new
    @procedure ||= Procedure.new
    @procedure.module_api_carto ||= ModuleAPICarto.new
  end

  def create
    @procedure = Procedure.new(create_procedure_params)
    @procedure.module_api_carto = ModuleAPICarto.new(create_module_api_carto_params) if @procedure.valid?

    unless @procedure.save
      flash.now.alert = @procedure.errors.full_messages.join('<br />').html_safe
      return render 'new'
    end

    flash.notice = 'Procédure enregistrée'
    redirect_to admin_procedure_types_de_champ_path(procedure_id: @procedure.id)
  end

  def update
    @procedure = current_administrateur.procedures.find(params[:id])

    unless @procedure.update_attributes(create_procedure_params)
      flash.now.alert = @procedure.errors.full_messages.join('<br />').html_safe
      return render 'edit'
    end

    flash.notice = 'Préocédure modifiée'
    redirect_to admin_procedures_path
  end

  def archive
    @procedure = current_administrateur.procedures.find(params[:procedure_id])
    @procedure.update_attributes({archived: params[:archive]})

    flash.notice = 'Procédure éditée'
    redirect_to admin_procedures_path

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inéxistante'
    redirect_to admin_procedures_path
  end

  private

  def create_procedure_params
    params.require(:procedure).permit(:libelle, :description, :organisation, :direction, :lien_demarche, :euro_flag, :logo, module_api_carto_attributes: [:id, :use_api_carto, :quartiers_prioritaires, :cadastre]).merge(administrateur_id: current_administrateur.id)
  end

  def create_module_api_carto_params
    params.require(:procedure).require(:module_api_carto_attributes).permit(:id, :use_api_carto, :quartiers_prioritaires, :cadastre)
  end

  def informations
    @procedure = current_administrateur.procedures.find(params[:id]).decorate

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inéxistante'
    redirect_to admin_procedures_path
  end
end
