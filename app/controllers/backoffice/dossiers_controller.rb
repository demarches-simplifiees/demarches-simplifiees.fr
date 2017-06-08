class Backoffice::DossiersController < Backoffice::DossiersListController
  respond_to :html, :xlsx, :ods, :csv

  before_action :ensure_gestionnaire_is_authorized, only: :show

  def index
    return redirect_to backoffice_invitations_path if current_gestionnaire.avis.any?

    procedure = current_gestionnaire.procedure_filter

    if procedure.nil?
      procedure_list = dossiers_list_facade.gestionnaire_procedures_name_and_id_list

      if procedure_list.count == 0
        flash.alert = "Vous n'avez aucune procédure d'affectée."
        return redirect_to root_path
      end

      procedure = procedure_list.first[:id]
    end

    redirect_to backoffice_dossiers_procedure_path(id: procedure)
  end

  def show
    dossier_id = params[:id]
    create_dossier_facade dossier_id

    unless @facade.nil?
      @champs_private = @facade.champs_private

      @headers_private = @champs_private.select { |champ| champ.type_champ == 'header_section' }
    end

    # if the current_gestionnaire does not own the dossier, it is here to give an advice
    # and it should not remove the notifications
    if current_gestionnaire.dossiers.find_by(id: dossier_id).present?
      Notification.where(dossier_id: dossier_id).update_all(already_read: true)
    end

    @new_avis = Avis.new(introduction: "Bonjour, merci de me donner votre avis sur ce dossier.")
  end

  def filter
    super

    redirect_to backoffice_dossiers_path(liste: param_liste)
  end

  def download_dossiers_tps
    procedure = Procedure.find_by(id: params[:procedure_id])
    export = procedure.generate_export

    respond_to do |format|
      format.csv { send_data(SpreadsheetArchitect.to_csv(data: export[:data], headers: export[:headers]), filename: 'dossiers.csv') }
      format.xlsx { send_data(SpreadsheetArchitect.to_xlsx(data: export[:data], headers: export[:headers]), filename: 'dossiers.xlsx') }
      format.ods { send_data(SpreadsheetArchitect.to_ods(data: export[:data], headers: export[:headers]), filename: 'dossiers.ods') }
    end
  end

  def search
    @search_terms = params[:q]

    # exact id match?
    if @search_terms.to_i != 0
      @dossiers = current_gestionnaire.dossiers.where(id: @search_terms.to_i)
    end

    @dossiers = Dossier.none if @dossiers.nil?

    # full text search
    unless @dossiers.any?
      @dossiers = Search.new(
          gestionnaire: current_gestionnaire,
          query: @search_terms,
          page: params[:page]
      ).results
    end

    smart_listing_create :search,
                         @dossiers,
                         partial: "backoffice/dossiers/list",
                         array: true,
                         default_sort: dossiers_list_facade.service.default_sort

  rescue RuntimeError
    smart_listing_create :search,
                         [],
                         partial: "backoffice/dossiers/list",
                         array: true,
                         default_sort: dossiers_list_facade.service.default_sort
  end

  def receive
    create_dossier_facade params[:dossier_id]

    dossier = @facade.dossier

    dossier.received!
    flash.notice = 'Dossier considéré comme reçu.'

    NotificationMailer.send_notification(dossier, dossier.procedure.received_mail_template).deliver_now!

    redirect_to backoffice_dossier_path(id: dossier.id)
  end

  def refuse
    create_dossier_facade params[:dossier_id]

    dossier = @facade.dossier

    dossier.next_step! 'gestionnaire', 'refuse'
    flash.notice = 'Dossier considéré comme refusé.'

    NotificationMailer.send_notification(dossier, dossier.procedure.refused_mail_template).deliver_now!

    redirect_to backoffice_dossier_path(id: dossier.id)
  end

  def without_continuation
    create_dossier_facade params[:dossier_id]

    dossier = @facade.dossier

    dossier.next_step! 'gestionnaire', 'without_continuation'
    flash.notice = 'Dossier considéré comme sans suite.'

    NotificationMailer.send_notification(dossier, dossier.procedure.without_continuation_mail_template).deliver_now!

    redirect_to backoffice_dossier_path(id: dossier.id)
  end

  def close
    create_dossier_facade params[:dossier_id]

    dossier = @facade.dossier

    dossier.next_step! 'gestionnaire', 'close'
    flash.notice = 'Dossier traité avec succès.'

    NotificationMailer.send_notification(dossier, dossier.procedure.closed_mail_template).deliver_now!

    redirect_to backoffice_dossier_path(id: dossier.id)
  end

  def follow
    follow = current_gestionnaire.toggle_follow_dossier params[:dossier_id]

    current_gestionnaire.dossiers.find(params[:dossier_id]).next_step! 'gestionnaire', 'follow'

    flash.notice = (follow.class == Follow ? 'Dossier suivi' : 'Dossier relaché')
    redirect_to request.referer
  end

  def reload_smartlisting
    begin
      @liste = URI(request.referer).query.split('=').second
    rescue NoMethodError
      @liste = cookies[:liste] || 'all_state'
    end

    smartlisting_dossier

    render 'backoffice/dossiers/index', formats: :js
  end

  def archive
    facade = create_dossier_facade params[:id]
    unless facade.dossier.archived
      facade.dossier.update(archived: true)
      flash.notice = 'Dossier archivé'
    end
    redirect_to backoffice_dossiers_path
  end


  def unarchive
    @dossier = Dossier.find(params[:id])
    if @dossier.archived
      @dossier.update(archived: false)
      flash.notice = 'Dossier désarchivé'
    end
    redirect_to backoffice_dossier_path(@dossier)
  end

  def reopen
    create_dossier_facade params[:dossier_id]

    @facade.dossier.replied!
    flash.notice = 'Dossier réouvert.'

    redirect_to backoffice_dossiers_path
  end

  private

  def ensure_gestionnaire_is_authorized
    unless current_gestionnaire.can_view_dossier?(params[:id])
      flash.alert = t('errors.messages.dossier_not_found')
      redirect_to url_for(controller: '/backoffice')
    end
  end

  def create_dossier_facade dossier_id
    @facade = DossierFacades.new dossier_id, current_gestionnaire.email

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(controller: '/backoffice')
  end

  def retrieve_procedure
    return if params[:procedure_id].blank?
    current_gestionnaire.procedures.find params[:procedure_id]
  end
end
