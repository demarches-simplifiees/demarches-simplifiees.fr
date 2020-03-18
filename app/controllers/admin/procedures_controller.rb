class Admin::ProceduresController < AdminController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :retrieve_procedure, only: [:show, :delete_logo, :delete_deliberation, :delete_notice, :publish_validate, :publish]

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
      current_administrateur.procedures.closes.order(published_at: :desc),
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
    if @procedure.brouillon?
      @procedure_lien = commencer_test_url(path: @procedure.path)
    else
      @procedure_lien = commencer_url(path: @procedure.path)
    end
    @procedure.path = @procedure.suggested_path(current_administrateur)
    @current_administrateur = current_administrateur
  end

  def destroy
    procedure = current_administrateur.procedures.find(params[:id])

    if procedure.can_be_deleted_by_administrateur?
      procedure.discard_and_keep_track!(current_administrateur)

      flash.notice = 'Démarche supprimée'
      redirect_to admin_procedures_draft_path
    else
      render json: {}, status: 403
    end
  end

  def publish_validate
    @procedure.assign_attributes(publish_params)
  end

  def publish
    @procedure.assign_attributes(publish_params)

    @procedure.publish_or_reopen!(current_administrateur)

    flash.notice = "Démarche publiée"
    render js: "window.location='#{admin_procedures_path}'"
  rescue ActiveRecord::RecordInvalid
    respond_to do |format|
      format.js { render :publish_validate }
    end
  end

  def transfer
    admin = Administrateur.by_email(params[:email_admin].downcase)

    if admin.nil?
      respond_to do |format|
        format.js { render :transfer, status: :not_found }
      end
    else
      procedure = current_administrateur.procedures.find(params[:procedure_id])
      procedure.clone(admin, false)

      flash.now.notice = "La démarche a correctement été clonée vers le nouvel administrateur."

      respond_to do |format|
        format.js
      end
    end
  end

  def archive
    procedure = current_administrateur.procedures.find(params[:procedure_id])
    procedure.close!

    flash.notice = "Démarche close"
    redirect_to admin_procedures_path

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Démarche inexistante'
    redirect_to admin_procedures_path
  end

  def clone
    procedure = Procedure.find(params[:procedure_id])
    new_procedure = procedure.clone(current_administrateur, cloned_from_library?)

    if new_procedure.valid?
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
      .publiees_ou_closes
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

  def delete_logo
    @procedure.logo.purge_later

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

  def publish_params
    params.permit(:path, :lien_site_web)
  end

  def procedure_params
    editable_params = [:libelle, :description, :organisation, :direction, :lien_site_web, :cadre_juridique, :deliberation, :notice, :web_hook_url, :euro_flag, :logo, :auto_archive_on]
    permited_params = if @procedure&.locked?
      params.require(:procedure).permit(*editable_params)
    else
      params.require(:procedure).permit(*editable_params, :duree_conservation_dossiers_dans_ds, :duree_conservation_dossiers_hors_ds, :for_individual, :path)
    end
    permited_params
  end
end
