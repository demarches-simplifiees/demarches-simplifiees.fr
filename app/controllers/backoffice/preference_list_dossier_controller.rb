class Backoffice::PreferenceListDossierController < Backoffice::DossiersListController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :authenticate_gestionnaire!
  before_action :params_procedure_id

  def add
    PreferenceListDossier.create(
        libelle: params[:libelle],
        table: (params[:table].empty? ? nil : params[:table]),
        attr: params[:attr],
        attr_decorate: params[:attr_decorate],
        bootstrap_lg: params[:bootstrap_lg],
        order: nil,
        filter: nil,
        gestionnaire: current_gestionnaire,
        procedure_id: params_procedure_id
    )

    render partial: path, formats: :js
  end

  def reload_pref_list
    dossiers_list_facade

    render partial: 'backoffice/dossiers/pref_list', id: params_procedure_id
  end

  def delete
    PreferenceListDossier.delete(params[:pref_id])

    render partial: path, formats: :js
  end

  private

  def path
    Features.opensimplif ? 'opensimplif/pref_list' : 'backoffice/dossiers/pref_list'
  end

  def params_procedure_id
    @procedure_id ||= params[:procedure_id]
  end

  def retrieve_procedure
    return if params[:procedure_id].blank?
    current_gestionnaire.procedures.find params_procedure_id
  end
end
