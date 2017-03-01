class Backoffice::DossiersListController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :authenticate_gestionnaire!

  def index
    cookies[:liste] = param_liste

    unless DossiersListGestionnaireService.dossiers_liste_libelle.include?(param_liste)
      cookies[:liste] = 'all_state'
    end

    dossiers_list_facade param_liste
    dossiers_list_facade.service.change_sort! param_sort unless param_smart_listing.nil?
    dossiers_list_facade.service.change_page! param_page

    smartlisting_dossier
  end

  def filter
    dossiers_list_facade param_liste
    dossiers_list_facade.service.add_filter param_filter
  end

  def dossiers_list_facade liste='all_state'
    @facade_data_view ||= DossiersListFacades.new current_gestionnaire, liste, retrieve_procedure
  end

  def smartlisting_dossier dossiers_list=nil, liste='all_state'
    dossiers_list_facade liste
    service = dossiers_list_facade.service

    @dossiers_archived = archived_dossier_list

    if param_page.nil?
      params[:dossiers_smart_listing] = {page: dossiers_list_facade.service.default_page}
    end

    default_smart_listing_create :new_dossiers, service.nouveaux
    default_smart_listing_create :follow_dossiers, service.suivi
    default_smart_listing_create :all_state_dossiers, service.all_state
    default_smart_listing_create :dossiers_archived, service.archive
  end

  private

  def default_smart_listing_create name, collection
    smart_listing_create name,
                         collection,
                         partial: 'backoffice/dossiers/list',
                         array: true,
                         default_sort: dossiers_list_facade.service.default_sort
  end

  def param_smart_listing
    params[:dossiers_smart_listing]
  end

  def param_page
    unless param_smart_listing.nil?
      return 1 if params[:dossiers_smart_listing][:page].blank?
      params[:dossiers_smart_listing][:page]
    end
  end

  def param_sort
    params[:dossiers_smart_listing][:sort] unless param_smart_listing.nil?
  end

  def param_filter
    params[:filter_input]
  end

  def param_liste
    @liste ||= params[:liste] || cookies[:liste] || 'all_state'
  end
end
