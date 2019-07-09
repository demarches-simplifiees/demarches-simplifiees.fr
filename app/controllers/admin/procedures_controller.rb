class Admin::ProceduresController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :retrieve_procedure, only: [:show, :edit, :delete_logo, :delete_deliberation, :delete_notice]

  def index
    if current_administrateur.procedures.count != 0
      @procedures = smart_listing_create :procedures,
        current_administrateur.procedures.publiees.order(published_at: :desc),
        partial: "admin/procedures/list",
        array: true

      active_class
    else
      redirect_to new_from_existing_admin_procedures_path
    end
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
    @availability = @procedure.path_availability(current_administrateur, @path)
  end

  def destroy
    procedure = current_administrateur.procedures.find(params[:id])

    if procedure.publiee_ou_archivee?
      return render json: {}, status: 401
    end

    procedure.reset!
    procedure.destroy

    flash.notice = 'Démarche supprimée'
    redirect_to admin_procedures_draft_path
  end

  def new
    @procedure ||= Procedure.new
    @availability = Procedure::PATH_AVAILABLE
  end

  def create
    @procedure = Procedure.new(procedure_params.merge(administrateurs: [current_administrateur]))
    @path = @procedure.path
    @availability = Procedure.path_availability(current_administrateur, @procedure.path)

    if !@procedure.save
      flash.now.alert = @procedure.errors.full_messages
      render 'new'
    else
      flash.notice = 'Démarche enregistrée.'
      gestionnaire = Gestionnaire.find_by(email: current_administrateur.email)
      if gestionnaire
        gestionnaire.assign_to_procedure(@procedure)
      end

      redirect_to champs_procedure_path(@procedure)
    end
  end

  def update
    @procedure = current_administrateur.procedures.find(params[:id])

    if !@procedure.update(procedure_params)
      flash.now.alert = @procedure.errors.full_messages
      @path = procedure_params[:path]
      if @path.present?
        @availability = @procedure.path_availability(current_administrateur, @path)
      end
      render 'edit'
    elsif @procedure.brouillon?
      reset_procedure
      flash.notice = 'Démarche modifiée. Tous les dossiers de cette démarche ont été supprimés.'
      redirect_to edit_admin_procedure_path(id: @procedure.id)
    else
      flash.notice = 'Démarche modifiée.'
      redirect_to edit_admin_procedure_path(id: @procedure.id)
    end
  end

  def publish
    path = params[:path]
    procedure = current_administrateur.procedures.find(params[:procedure_id])

    procedure.path = path
    if !procedure.validate
      flash.alert = 'Lien de la démarche invalide'
      return redirect_to admin_procedures_path
    else
      procedure.path = nil
    end

    if procedure.publish_or_reopen!(current_administrateur, path)
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
      .includes(:administrateurs, :service)
      .where(id: significant_procedure_ids)
      .group_by(&:organisation_name)
      .sort_by { |_, procedures| procedures.first.created_at }
    render layout: 'application'
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
    json_path_list = Procedure
      .find_with_path(params[:request])
      .order(:id)
      .map do |procedure|
        {
          label: procedure.path,
          mine: current_administrateur.owns?(procedure)
        }
      end.to_json

    render json: json_path_list
  end

  def check_availability
    path = params[:procedure][:path]
    procedure_id = params[:procedure][:id]

    if procedure_id.present?
      procedure = current_administrateur.procedures.find(procedure_id)
      @availability = procedure.path_availability(current_administrateur, path)
    else
      @availability = Procedure.path_availability(current_administrateur, path)
    end
  end

  def delete_logo
    @procedure.remove_logo!
    @procedure.save

    flash.notice = 'le logo a bien été supprimé'
    redirect_to edit_admin_procedure_path(@procedure)
  end

  def delete_deliberation
    @procedure.deliberation.purge_later

    flash.notice = 'la délibération a bien été supprimée'
    redirect_to edit_admin_procedure_path(@procedure)
  end

  def delete_notice
    @procedure.notice.purge_later

    flash.notice = 'la notice a bien été supprimée'
    redirect_to edit_admin_procedure_path(@procedure)
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
      params.require(:procedure).permit(*editable_params, :duree_conservation_dossiers_dans_ds, :duree_conservation_dossiers_hors_ds, :for_individual, :individual_with_siret, :ask_birthday, :path)
    end
  end
end
