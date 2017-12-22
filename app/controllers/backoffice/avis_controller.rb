class Backoffice::AvisController < ApplicationController
  before_action :authenticate_gestionnaire!

  def create
    avis = Avis.new(create_params.merge(claimant: current_gestionnaire, dossier: dossier, confidentiel: true))

    if avis.save
      flash[:notice] = "Votre demande d'avis a bien été envoyée à #{avis.email_to_display}"
    end

    redirect_to backoffice_dossier_path(dossier)
  end

  def update
    if avis.update(update_params)
      NotificationService.new('avis', params[:dossier_id]).notify
      flash[:notice] = 'Merci, votre avis a été enregistré.'
    end

    redirect_to backoffice_dossier_path(avis.dossier_id)
  end

  private

  def dossier
    current_gestionnaire.dossiers.find(params[:dossier_id])
  end

  def avis
    current_gestionnaire.avis.find(params[:id])
  end

  def create_params
    params.require(:avis).permit(:email, :introduction)
  end

  def update_params
    params.require(:avis).permit(:answer)
  end
end
