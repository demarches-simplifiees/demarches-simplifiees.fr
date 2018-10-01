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
  end

  def edit
    @path = @procedure.path || @procedure.default_path
    @available = @procedure.path_available?(@path)
    @mine = @procedure.path_is_mine?(@path)
  end

  def hide
    procedure = current_administrateur.procedures.find(params[:id])
    procedure.hide!

    flash.notice = "Démarche supprimée, en cas d'erreur #{helpers.contact_link('contactez nous', tags: 'démarche supprimée')}"
    redirect_to admin_procedures_draft_path
  end

  def destroy
    procedure = current_administrateur.procedures.find(params[:id])

    if procedure.publiee_ou_archivee?
      return render json: {}, status: 401
    end

    procedure.destroy

    flash.notice = 'Démarche supprimée'
    redirect_to admin_procedures_draft_path
  end

  def new
    @procedure ||= Procedure.new
    @procedure.module_api_carto ||= ModuleAPICarto.new
    @available = true
    @mine = true
  end

  def create
    @procedure = Procedure.new(procedure_params)

    if @procedure.valid?
      @procedure.module_api_carto = ModuleAPICarto.new(create_module_api_carto_params)
    end

    @path = params.require(:procedure).permit(:path)[:path]
    @available = !ProcedurePath.exists?(path: @path)
    @mine = ProcedurePath.mine?(current_administrateur, @path)

    if !@procedure.validate
      flash.now.alert = @procedure.errors.full_messages
      return render 'new'
    elsif Flipflop.publish_draft? && !ProcedurePath.valid?(Procedure.last, @path)
      # FIXME: The code abow is a horrible hack that we need until we migrated path directly on procedure model
      flash.now.alert = 'Lien de la démarche invalide.'
      return render 'new'
    else
      @procedure.save!
      if Flipflop.publish_draft?
        @procedure.publish_with_path!(@path)
      end
      flash.notice = 'Démarche enregistrée.'
    end

    redirect_to admin_procedure_types_de_champ_path(procedure_id: @procedure.id)
  end

  def update
    @procedure = current_administrateur.procedures.find(params[:id])
    path = params.require(:procedure).permit(:path)[:path]

    if !@procedure.update(procedure_params)
      flash.alert = @procedure.errors.full_messages
    elsif Flipflop.publish_draft? && @procedure.brouillon?
      if ProcedurePath.valid?(@procedure, path)
        @procedure.publish_with_path!(path)
        reset_procedure
        flash.notice = 'Démarche modifiée. Tous les brouillons de cette démarche ont été supprimés.'
      else
        flash.alert = 'Lien de la démarche invalide.'
      end
    else
      reset_procedure
      flash.notice = 'Démarche modifiée. Tous les brouillons de cette démarche ont été supprimés.'
    end

    redirect_to edit_admin_procedure_path(id: @procedure.id)
  end

  def publish
    procedure = current_administrateur.procedures.find(params[:procedure_id])

    if !ProcedurePath.valid?(procedure, params[:procedure_path])
      flash.alert = 'Lien de la démarche invalide'
      return redirect_to admin_procedures_path
    end

    if procedure.publish_or_reopen!(params[:procedure_path])
      flash.notice = "Démarche publiée"
      redirect_to admin_procedures_path
    else
      @mine = false
      render '/admin/procedures/publish', formats: 'js'
    end
  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Démarche inexistante'
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

      flash.now.notice = "La démarche a correctement été clonée vers le nouvel administrateur."

      render '/admin/procedures/transfer', formats: 'js', status: 200
    end
  end

  def archive
    procedure = current_administrateur.procedures.find(params[:procedure_id])
    procedure.archive!

    flash.notice = "Démarche archivée"
    redirect_to admin_procedures_path

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Démarche inexistante'
    redirect_to admin_procedures_path
  end

  def clone
    procedure = Procedure.find(params[:procedure_id])
    new_procedure = procedure.clone(current_administrateur, cloned_from_library?)

    if new_procedure.save
      flash.notice = 'Démarche clonée'
      redirect_to edit_admin_procedure_path(id: new_procedure.id)
    else
      if cloned_from_library?
        flash.alert = new_procedure.errors.full_messages
        redirect_to new_from_existing_admin_procedures_path
      else
        flash.alert = new_procedure.errors.full_messages
        redirect_to admin_procedures_path
      end
    end

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Démarche inexistante'
    redirect_to admin_procedures_path
  end

  SIGNIFICANT_DOSSIERS_THRESHOLD = 30

  def new_from_existing
    significant_procedure_ids = Procedure
      .publiees_ou_archivees
      .joins(:dossiers)
      .group("procedures.id")
      .having("count(dossiers.id) >= ?", SIGNIFICANT_DOSSIERS_THRESHOLD)
      .pluck('procedures.id')

    @grouped_procedures = Procedure
      .includes(:administrateur, :service)
      .where(id: significant_procedure_ids)
      .group_by(&:organisation_name)
      .sort_by { |_, procedures| procedures.first.created_at }
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
      .find_with_path(params[:request])
      .pluck('procedure_paths.path', :administrateur_id)
      .map do |path, administrateur_id|
        {
          label: path,
          mine: administrateur_id == current_administrateur.id
        }
      end.to_json

    render json: json_path_list
  end

  def check_availability
    path = params[:procedure][:path]
    procedure_id = params[:procedure][:id]

    if procedure_id.present?
      procedure = current_administrateur.procedures.find(procedure_id)
      @available = procedure.path_available?(path)
      @mine = procedure.path_is_mine?(path)
    else
      @available = !ProcedurePath.exists?(path: path)
      @mine = ProcedurePath.mine?(current_administrateur, path)
    end
  end

  def delete_logo
    procedure = Procedure.find(params[:id])

    procedure.remove_logo!
    procedure.save

    flash.notice = 'le logo a bien été supprimé'
    redirect_to edit_admin_procedure_path(procedure)
  end

  def delete_deliberation
    procedure = Procedure.find(params[:id])

    procedure.deliberation.purge_later

    flash.notice = 'la délibération a bien été supprimée'
    redirect_to edit_admin_procedure_path(procedure)
  end

  def delete_notice
    procedure = Procedure.find(params[:id])

    procedure.notice.purge_later

    flash.notice = 'la notice a bien été supprimée'
    redirect_to edit_admin_procedure_path(procedure)
  end

  private

  def cloned_from_library?
    params[:from_new_from_existing].present?
  end

  def procedure_params
    editable_params = [:libelle, :description, :organisation, :direction, :lien_site_web, :cadre_juridique, :deliberation, :notice, :web_hook_url, :euro_flag, :logo, :auto_archive_on]
    if @procedure&.locked?
      params.require(:procedure).permit(*editable_params)
    else
      params.require(:procedure).permit(*editable_params, :duree_conservation_dossiers_dans_ds, :duree_conservation_dossiers_hors_ds, :lien_demarche, :for_individual, :individual_with_siret, :ask_birthday, module_api_carto_attributes: [:id, :use_api_carto, :quartiers_prioritaires, :cadastre]).merge(administrateur_id: current_administrateur.id)
    end
  end

  def create_module_api_carto_params
    params.require(:procedure).require(:module_api_carto_attributes).permit(:id, :use_api_carto, :quartiers_prioritaires, :cadastre)
  end
end
