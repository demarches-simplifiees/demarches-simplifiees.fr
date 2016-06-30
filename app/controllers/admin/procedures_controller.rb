class Admin::ProceduresController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :retrieve_procedure, only: [:show, :edit]
  before_action :procedure_locked?, only: [:edit]

  def index
    @procedures = smart_listing_create :procedures,
                         current_administrateur.procedures.where(published: true, archived: false).order(created_at: :desc),
                         partial: "admin/procedures/list",
                         array: true

    active_class
  end

  def archived
    @procedures = smart_listing_create :procedures,
                                       current_administrateur.procedures.where(archived: true).order(created_at: :desc),
                                       partial: "admin/procedures/list",
                                       array: true

    archived_class

    render 'index'
  end

  def draft
    @procedures = smart_listing_create :procedures,
                                       current_administrateur.procedures.where(published: false, archived: false).order(created_at: :desc),
                                       partial: "admin/procedures/list",
                                       array: true

    draft_class

    render 'index'
  end


  def show
    @facade = AdminProceduresShowFacades.new @procedure.decorate
  end

  def edit

  end

  def destroy
    procedure = Procedure.find(params[:id])

    return render json: {}, status: 401 if procedure.published? || procedure.archived?

    procedure.destroy

    flash.notice = 'Procédure supprimée'
    redirect_to admin_procedures_draft_path
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
    procedure = current_administrateur.procedures.find(params[:procedure_id])

    test_procedure = ProcedurePath.new(
        {
            path: params[:procedure_path],
            procedure: procedure,
            administrateur: procedure.administrateur
        })
    unless test_procedure.validate
      flash.alert = 'Lien de la procédure invalide'
      return redirect_to admin_procedures_path
    end

    procedure_path = ProcedurePath.find_by_path(params[:procedure_path])
    if (procedure_path)
      if (procedure_path.administrateur_id == current_administrateur.id)
        procedure_path.procedure.archive
      else
        @mine = false
        return render '/admin/procedures/publish', formats: 'js'
      end
    end

    procedure.publish(params[:procedure_path])
    flash.notice = "Procédure publiée"
    render js: "window.location = '#{admin_procedures_path}'"

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inéxistante'
    redirect_to admin_procedures_path
  end

  def archive
    procedure = current_administrateur.procedures.find(params[:procedure_id])
    procedure.archive

    flash.notice = "Procédure archivée"
    redirect_to admin_procedures_path

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inéxistante'
    redirect_to admin_procedures_path
  end

  def clone
    procedure = current_administrateur.procedures.find(params[:procedure_id])

    new_procedure = procedure.clone
    if new_procedure
      flash.notice = 'Procédure clonée'
      redirect_to edit_admin_procedure_path(id: new_procedure.id)
    else
      flash.now.alert = procedure.errors.full_messages.join('<br />').html_safe
      render 'index'
    end

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inéxistante'
    redirect_to admin_procedures_path
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

  def path_list
    render json: ProcedurePath.where("path LIKE '%#{params[:request]}%'").pluck(:path, :administrateur_id).inject([]) {
      |acc, value| acc.push({ label: value.first, mine: value.second == current_administrateur.id })
    }.to_json
  end

  private

  def create_procedure_params
    params.require(:procedure).permit(:libelle, :description, :organisation, :direction, :lien_demarche, :euro_flag, :logo, :cerfa_flag, module_api_carto_attributes: [:id, :use_api_carto, :quartiers_prioritaires, :cadastre]).merge(administrateur_id: current_administrateur.id)
  end

  def create_module_api_carto_params
    params.require(:procedure).require(:module_api_carto_attributes).permit(:id, :use_api_carto, :quartiers_prioritaires, :cadastre)
  end
end
