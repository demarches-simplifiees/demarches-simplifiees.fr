class Backoffice::ProcedureFilterController < ApplicationController
  before_action :authenticate_gestionnaire!

  def index
    @gestionnaire = current_gestionnaire
    @procedures = current_gestionnaire.procedures
  end

  def update

    current_gestionnaire.update_attribute(:procedure_filter, params[:procedure_filter])

    flash.notice = 'Filtre mis à jour'
    redirect_to backoffice_filtres_path
  end
end