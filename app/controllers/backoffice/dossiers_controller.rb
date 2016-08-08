class Backoffice::DossiersController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :authenticate_gestionnaire!

  def index
    @liste = params[:liste] || 'a_traiter'

    smartlisting_dossier

    total_dossiers_per_state
  end

  def show
    create_dossier_facade params[:id]
    @champs = @facade.champs_private unless @facade.nil?
  end

  def search
    @search_terms = params[:q]
    @dossiers_search, @dossier = Dossier.search(current_gestionnaire, @search_terms)

    unless @dossiers_search.empty?
      @dossiers_search = @dossiers_search.paginate(:page => params[:page]).decorate
    end

    @dossier = @dossier.decorate unless @dossier.nil?

    total_dossiers_per_state
  rescue RuntimeError
    @dossiers_search = []
  end

  def valid
    create_dossier_facade params[:dossier_id]

    @facade.dossier.next_step! 'gestionnaire', 'valid'
    flash.notice = 'Dossier confirmé avec succès.'

    NotificationMailer.dossier_validated(@facade.dossier).deliver_now!

    render 'show'
  end

  def close
    create_dossier_facade params[:dossier_id]

    @facade.dossier.next_step! 'gestionnaire', 'close'
    flash.notice = 'Dossier traité avec succès.'

    render 'show'
  end

  def follow
    follow = current_gestionnaire.toggle_follow_dossier params[:dossier_id]

    flash.notice = (follow.class == Follow ? 'Dossier suivi' : 'Dossier relaché')
    redirect_to request.referer
  end

  def reload_smartlisting
    begin
      @liste = URI(request.referer).query.split('=').second
    rescue NoMethodError
      @liste = 'a_traiter'
    end
    smartlisting_dossier

    render 'backoffice/dossiers/index', formats: :js
  end

  private

  def smartlisting_dossier
    @dossiers = smart_listing_create :dossiers,
                                     dossiers_to_display,
                                     partial: "backoffice/dossiers/list",
                                     array: true
  end

  def dossiers_to_display
    {'a_traiter' => waiting_for_gestionnaire,
     'en_attente' => waiting_for_user,
     'termine' => termine,
     'suivi' => suivi}[@liste]
  end

  def waiting_for_gestionnaire
    @a_traiter_class = (@liste == 'a_traiter' ? 'active' : '')
    @waiting_for_gestionnaire ||= current_gestionnaire.dossiers_filter.waiting_for_gestionnaire
  end

  def waiting_for_user
    @en_attente_class = (@liste == 'en_attente' ? 'active' : '')
    @waiting_for_user ||= current_gestionnaire.dossiers_filter.waiting_for_user
  end

  def termine
    @termine_class = (@liste == 'termine' ? 'active' : '')
    @termine ||= current_gestionnaire.dossiers_filter.termine
  end

  def suivi
    @suivi_class = (@liste == 'suivi' ? 'active' : '')
    @suivi ||= current_gestionnaire.dossiers_follow
  end

  def total_dossiers_per_state
    @dossiers_a_traiter_total = waiting_for_gestionnaire.count
    @dossiers_en_attente_total = waiting_for_user.count
    @dossiers_termine_total = termine.count
    @dossiers_suivi_total = suivi.count
  end

  def create_dossier_facade dossier_id
    @facade = DossierFacades.new dossier_id, current_gestionnaire.email

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(controller: '/backoffice')
  end
end
