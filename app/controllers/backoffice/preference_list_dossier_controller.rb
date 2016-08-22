class Backoffice::PreferenceListDossierController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :authenticate_gestionnaire!

  def add
    PreferenceListDossier.create(
        libelle: params[:libelle],
        table: params[:table],
        attr: params[:attr],
        attr_decorate: params[:attr_decorate],
        bootstrap_lg: params[:bootstrap_lg],
        order: nil,
        filter: nil,
        gestionnaire: current_gestionnaire
    )

    render partial: 'backoffice/dossiers/pref_list', formats: :js
  end

  def reload_pref_list
    render partial: 'backoffice/dossiers/pref_list'
  end

  def delete
    PreferenceListDossier.delete(params[:pref_id])

    render partial: 'backoffice/dossiers/pref_list', formats: :js
  end
end
