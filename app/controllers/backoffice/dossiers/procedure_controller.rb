class Backoffice::Dossiers::ProcedureController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :authenticate_gestionnaire!

  def show
    cookies[:liste] = params[:liste] || cookies[:liste] || 'a_traiter'
    smartlisting_dossier cookies[:liste]

    current_gestionnaire.update_column :procedure_filter, [params[:id]]

    render 'backoffice/dossiers/index'
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Cette procédure n'existe pas ou vous n'y avez pas accès."
    redirect_to backoffice_dossiers_path
  end

  private

  def smartlisting_dossier liste
    create_dossiers_list_facade liste

    @dossiers = smart_listing_create :dossiers,
                                     @dossiers_list_facade.dossiers_to_display,
                                     partial: "backoffice/dossiers/list",
                                     array: true
  end

  def create_dossiers_list_facade liste='a_traiter'
    @dossiers_list_facade = DossiersListFacades.new current_gestionnaire, liste, retrieve_procedure
  end

  def retrieve_procedure
    current_gestionnaire.procedures.find params[:id]
  end
end
