class Backoffice::PrivateFormulairesController < ApplicationController
  before_action :authenticate_gestionnaire!

  def update
    dossier = current_gestionnaire.dossiers.find(params[:dossier_id])

    if params[:champs].present?
      ChampsService.save_champs dossier.champs_private, params
      champs_service_errors = ChampsService.build_error_messages(dossier.champs_private)

      if champs_service_errors.empty?
        flash[:notice] = "Formulaire enregistré"
      else
        flash[:alert] = champs_service_errors
      end
    end

    render 'backoffice/dossiers/formulaire_private', formats: :js
  end
end
