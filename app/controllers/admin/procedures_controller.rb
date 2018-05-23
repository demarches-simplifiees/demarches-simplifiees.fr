class Admin::ProceduresController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :retrieve_procedure, only: [:show, :edit]

  def index
    @procedures = smart_listing_create :procedures,
      current_administrateur.procedures.publiees.order(published_at: :desc),
      partial: "admin/procedures/list",
      array: true

    active_class
  end

  def archived
    @procedures = smart_listing_create :procedures,
      current_administrateur.procedures.archivees.order(published_at: :desc),
      partial: "admin/procedures/list",
      array: true

    archived_class

    render 'index'
  end

  def draft
    @procedures = smart_listing_create :procedures,
      current_administrateur.procedures.brouillons.order(created_at: :desc),
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

  def hide
    procedure = current_administrateur.procedures.find(params[:id])
    procedure.hide!

    flash.notice = "Procédure supprimée, en cas d'erreur contactez nous : contact@demarches-simplifiees.fr"
    redirect_to admin_procedures_draft_path
  end

  def destroy
    procedure = current_administrateur.procedures.find(params[:id])

    return render json: {}, status: 401 if procedure.publiee_ou_archivee?

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

    if !@procedure.save
      flash.now.alert = @procedure.errors.full_messages
      return render 'new'
    end

    flash.notice = 'Procédure enregistrée'
    redirect_to admin_procedure_types_de_champ_path(procedure_id: @procedure.id)
  end

  def update
    @procedure = current_administrateur.procedures.find(params[:id])

    if !@procedure.update(procedure_params)
      flash.now.alert = @procedure.errors.full_messages
      return render 'edit'
    end

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
      }
    )

    if new_procedure_path.validate
      new_procedure_path.delete
    else
      flash.alert = 'Lien de la procédure invalide'
      return redirect_to admin_procedures_path
    end

    procedure_path = ProcedurePath.find_by(path: params[:procedure_path])
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
    flash.alert = 'Procédure inexistante'
    redirect_to admin_procedures_path
  end

  def transfer
    admin = Administrateur.find_by(email: params[:email_admin].downcase)

    if admin.nil?
      render '/admin/procedures/transfer', formats: 'js', status: 404
    else
      procedure = current_administrateur.procedures.find(params[:procedure_id])
      clone_procedure = procedure.clone(admin, false)

      clone_procedure.save

      flash.now.notice = "La procédure a correctement été clonée vers le nouvel administrateur."

      render '/admin/procedures/transfer', formats: 'js', status: 200
    end
  end

  def archive
    procedure = current_administrateur.procedures.find(params[:procedure_id])
    procedure.archive

    flash.notice = "Procédure archivée"
    redirect_to admin_procedures_path

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inexistante'
    redirect_to admin_procedures_path
  end

  def clone
    procedure = Procedure.find(params[:procedure_id])
    new_procedure = procedure.clone(current_administrateur, cloned_from_library?)

    if new_procedure.save
      flash.notice = 'Procédure clonée'
      redirect_to edit_admin_procedure_path(id: new_procedure.id)
    else
      if cloned_from_library?
        flash.alert = new_procedure.errors.full_messages
        redirect_to new_from_existing_admin_procedures_path
      else
        flash.now.alert = new_procedure.errors.full_messages
        render 'index'
      end
    end

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inexistante'
    redirect_to admin_procedures_path
  end

  def new_from_existing
    procedures_with_more_than_30_dossiers_ids = Procedure
      .publiees_ou_archivees
      .joins(:dossiers)
      .group("procedures.id")
      .having("count(dossiers.id) > ?", 30)
      .pluck('procedures.id')

    @grouped_procedures = Procedure
      .where(id: procedures_with_more_than_30_dossiers_ids)
      .group_by(&:administrateur)
      .sort_by { |a, _| a.created_at }
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
    json_path_list = ProcedurePath
      .joins(:procedure)
      .where(procedures: { archived_at: nil })
      .where("path LIKE ?", "%#{params[:request]}%")
      .order(:id)
      .pluck(:path, :administrateur_id)
      .map do |path, administrateur_id|
        {
          label: path,
          mine: administrateur_id == current_administrateur.id
        }
      end.to_json

    render json: json_path_list
  end

  private

  def cloned_from_library?
    params[:from_new_from_existing].present?
  end

  def procedure_params
    editable_params = [:libelle, :description, :organisation, :direction, :lien_site_web, :notice, :web_hook_url, :euro_flag, :logo, :auto_archive_on]
    if @procedure.try(:locked?)
      params.require(:procedure).permit(*editable_params)
    else
      params.require(:procedure).permit(*editable_params, :lien_demarche, :cerfa_flag, :for_individual, :individual_with_siret, :ask_birthday, module_api_carto_attributes: [:id, :use_api_carto, :quartiers_prioritaires, :cadastre]).merge(administrateur_id: current_administrateur.id)
    end
  end

  def create_module_api_carto_params
    params.require(:procedure).require(:module_api_carto_attributes).permit(:id, :use_api_carto, :quartiers_prioritaires, :cadastre)
  end
end
