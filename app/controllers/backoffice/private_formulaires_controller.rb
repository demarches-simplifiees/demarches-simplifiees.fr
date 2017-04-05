class Backoffice::PrivateFormulairesController < ApplicationController
  before_action :authenticate_gestionnaire!

  def update
    dossier = current_gestionnaire.dossiers.find(params[:dossier_id])

    unless params[:champs].nil?
      champs_service_errors = ChampsService.save_formulaire dossier.champs_private, params

      if champs_service_errors.empty?
        flash[:notice] = "Formulaire enregistré"
      else
        flash[:alert] = (champs_service_errors.inject('') { |acc, error| acc+= error[:message]+'<br>' }).html_safe
      end
    end

    render 'backoffice/dossiers/formulaire_private', formats: :js
  end
end
