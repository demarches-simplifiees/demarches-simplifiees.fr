class Admin::ProceduresController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :retrieve_procedure, only: [:show, :edit]

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
    @procedure = Procedure.new(procedure_params)
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

    unless @procedure.update_attributes(procedure_params)
      flash.now.alert = @procedure.errors.full_messages.join('<br />').html_safe
      return render 'edit'
    end

    puts procedure_params

    flash.notice = 'Procédure modifiée'
    redirect_to edit_admin_procedure_path(id: @procedure.id)
  end

  def publish
    procedure = current_administrateur.procedures.find(params[:procedure_id])

    new_procedure_path = ProcedurePath.new(
        {
            path: params[:procedure_path],
            procedure: procedure,
            administrateur: procedure.administrateur
        })
    if new_procedure_path.validate
      new_procedure_path.delete
    else
      flash.alert = 'Lien de la procédure invalide'
      return redirect_to admin_procedures_path
    end

    procedure_path = ProcedurePath.find_by_path(params[:procedure_path])
    if procedure_path
      if procedure_path.administrateur_id == current_administrateur.id
        procedure_path.procedure.archive
        procedure_path.delete
      else
        @mine = false
        return render '/admin/procedures/publish', formats: 'js'
      end
    end

    procedure.publish!(params[:procedure_path])

    flash.notice = "Procédure publiée"
    render js: "window.location = '#{admin_procedures_path}'"

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inéxistante'
    redirect_to admin_procedures_path
  end

  def transfer
    admin = Administrateur.find_by_email(params[:email_admin])

    return render '/admin/procedures/transfer', formats: 'js', status: 404 if admin.nil?

    procedure = current_administrateur.procedures.find(params[:procedure_id])
    clone_procedure = procedure.clone

    clone_procedure.administrateur = admin
    clone_procedure.save

    flash.now.notice = "La procédure a correctement été cloné vers le nouvel administrateur."

    render '/admin/procedures/transfer', formats: 'js', status: 200
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
    render json: ProcedurePath
                     .joins(', procedures')
                     .where("procedures.id = procedure_paths.procedure_id")
                     .where("procedures.archived" => false)
                     .where("path LIKE '%#{params[:request]}%'")
                     .pluck(:path, :administrateur_id)
                     .inject([]) {
               |acc, value| acc.push({label: value.first, mine: value.second == current_administrateur.id})
           }.to_json
  end

  private

  def procedure_params
    editable_params = [:libelle, :description, :organisation, :direction, :lien_site_web, :lien_notice, :euro_flag, :logo, :auto_archive_on]
    if @procedure.try(:locked?)
      params.require(:procedure).permit(*editable_params)
    else
      params.require(:procedure).permit(*editable_params, :lien_demarche, :cerfa_flag, :for_individual, :individual_with_siret, module_api_carto_attributes: [:id, :use_api_carto, :quartiers_prioritaires, :cadastre]).merge(administrateur_id: current_administrateur.id)
    end
  end

  def create_module_api_carto_params
    params.require(:procedure).require(:module_api_carto_attributes).permit(:id, :use_api_carto, :quartiers_prioritaires, :cadastre)
  end
end
