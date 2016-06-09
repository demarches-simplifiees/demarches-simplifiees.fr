class Admin::ProceduresController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :retrieve_procedure, only: [:show, :edit]
  before_action :procedure_locked?, only: [:edit]

  def index
    @procedures = smart_listing_create :procedures,
                         current_administrateur.procedures.where(published: true, archived: false),
                         partial: "admin/procedures/list",
                         array: true

    active_class
  end

  def archived
    @procedures = smart_listing_create :procedures,
                                       current_administrateur.procedures.where(archived: true),
                                       partial: "admin/procedures/list",
                                       array: true

    archived_class

    render 'index'
  end

  def draft
    @procedures = smart_listing_create :procedures,
                                       current_administrateur.procedures.where(published: false, archived: false),
                                       partial: "admin/procedures/draft_list",
                                       array: true

    draft_class

    render 'index'
  end


  def show
    @facade = AdminProceduresShowFacades.new @procedure.decorate
  end

  def edit

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
    redirect_to edit_admin_procedure_path(id: @procedure.id)
  end

  def publish
    change_status({published: params[:published]})
  end

  def archive
    change_status({archived: params[:archive]})
  end

  def active_class
    @active_class = 'active'
  end

  def archived_class
    @archived_class = 'active'
  end

  def draft_class
    @draft_class = 'active'
  end

  private

  def create_procedure_params
    params.require(:procedure).permit(:libelle, :description, :organisation, :direction, :lien_demarche, :euro_flag, :logo, :cerfa_flag, module_api_carto_attributes: [:id, :use_api_carto, :quartiers_prioritaires, :cadastre]).merge(administrateur_id: current_administrateur.id)
  end

  def create_module_api_carto_params
    params.require(:procedure).require(:module_api_carto_attributes).permit(:id, :use_api_carto, :quartiers_prioritaires, :cadastre)
  end

  def change_status(status_options)
    @procedure = current_administrateur.procedures.find(params[:procedure_id])
    @procedure.update_attributes(status_options)

    flash.notice = 'Procédure éditée'
    redirect_to admin_procedures_path

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inéxistante'
    redirect_to admin_procedures_path
  end
end
