class Backoffice::DossiersListController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :authenticate_gestionnaire!

  def index
    cookies[:liste] = param_liste

    dossiers_list_facade param_liste
    dossiers_list_facade.service.change_sort! param_sort unless params[:dossiers_smart_listing].nil?

    smartlisting_dossier
  end

  def filter
    dossiers_list_facade param_liste
    dossiers_list_facade.service.add_filter param_filter
  end

  def dossiers_list_facade liste='a_traiter'
    @dossiers_list_facade ||= DossiersListFacades.new current_gestionnaire, liste, retrieve_procedure
  end

  def smartlisting_dossier
    @dossiers = smart_listing_create :dossiers,
                                     dossiers_list_facade.dossiers_to_display,
                                     partial: "backoffice/dossiers/list",
                                     array: true,
                                     default_sort: dossiers_list_facade.service.default_sort
  end

  private

  def param_sort
    params[:dossiers_smart_listing][:sort]
  end

  def param_filter
    params[:filter_input]
  end

  def param_liste
    @liste ||= params[:liste] || cookies[:liste] || 'a_traiter'
  end
end
