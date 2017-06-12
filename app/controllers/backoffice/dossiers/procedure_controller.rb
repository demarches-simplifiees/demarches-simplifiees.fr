class Backoffice::Dossiers::ProcedureController < Backoffice::DossiersListController
  def index
    super

    dossiers_list_facade.service.filter_procedure! params[:id]

    render 'backoffice/dossiers/index'
  rescue ActiveRecord::RecordNotFound
    flash.alert = "Cette procédure n'existe pas ou vous n'y avez pas accès."
    redirect_to backoffice_dossiers_path
  end

  def filter
    super

    redirect_to backoffice_dossiers_procedure_path(id: params[:id])
  end

  private

  def retrieve_procedure
    current_gestionnaire.procedures.find params[:id]
  end
end
