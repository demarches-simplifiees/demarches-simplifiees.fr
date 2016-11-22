class Backoffice::DossiersController < Backoffice::DossiersListController
  respond_to :html, :xlsx, :ods, :csv

  def index
    super
    dossiers_list_facade.service.filter_procedure_reset!
    @facade_data_view = dossiers_list_facade
  end

  def show
    create_dossier_facade params[:id]
    @champs = @facade.champs_private unless @facade.nil?
  end

  def filter
    super

    redirect_to backoffice_dossiers_path(liste: param_liste)
  end

  def download_dossiers_tps
    if procedure = Procedure.find_by(id: params[:procedure_id])
      dossiers = dossiers_list_facade(param_liste).dossiers_to_display
      respond_with Dossier.export_full_generation(dossiers, request.format)
    else
      dossiers = dossiers_list_facade(param_liste).dossiers_to_display
      respond_to do |format|
        format.xlsx { render xlsx: dossiers }
        format.ods  { render ods:  dossiers }
        format.csv  { render csv:  dossiers }
      end
    end
  end

  def search
    @search_terms = params[:q]

    # exact id match?
    @dossier = Dossier.where(id: @search_terms)

    # full text search
    unless @dossier.any?
      @dossier ||= Search.new(
        gestionnaire: current_gestionnaire,
        query: @search_terms,
        page: params[:page]
      ).results
    end

    smartlisting_dossier @dossier, 'search'
  rescue RuntimeError
    smartlisting_dossier [], 'search'
  end

  def valid
    create_dossier_facade params[:dossier_id]

    @facade.dossier.next_step! 'gestionnaire', 'valid'
    flash.notice = 'Dossier confirmé avec succès.'

    NotificationMailer.dossier_validated(@facade.dossier).deliver_now!

    render 'show'
  end

  def receive
    create_dossier_facade params[:dossier_id]

    @facade.dossier.next_step! 'gestionnaire', 'receive'
    flash.notice = 'Dossier considéré comme reçu.'

    NotificationMailer.dossier_received(@facade.dossier).deliver_now!

    render 'show'
  end

  def refuse
    create_dossier_facade params[:dossier_id]

    @facade.dossier.next_step! 'gestionnaire', 'refuse'
    flash.notice = 'Dossier considéré comme refusé.'

    NotificationMailer.dossier_refused(@facade.dossier).deliver_now!

    render 'show'
  end

  def without_continuation
    create_dossier_facade params[:dossier_id]

    @facade.dossier.next_step! 'gestionnaire', 'without_continuation'
    flash.notice = 'Dossier considéré comme sans suite.'

    NotificationMailer.dossier_without_continuation(@facade.dossier).deliver_now!

    render 'show'
  end

  def close
    create_dossier_facade params[:dossier_id]

    @facade.dossier.next_step! 'gestionnaire', 'close'
    flash.notice = 'Dossier traité avec succès.'

    NotificationMailer.dossier_closed(@facade.dossier).deliver_now!

    render 'show'
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
      @liste = cookies[:liste] || 'a_traiter'
    end

    dossiers_list_facade @liste
    smartlisting_dossier

    render 'backoffice/dossiers/index', formats: :js
  end

  private

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
