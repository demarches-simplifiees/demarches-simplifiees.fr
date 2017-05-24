class Backoffice::AvisController < ApplicationController

  before_action :authenticate_gestionnaire!

  def create
    avis = Avis.new(create_params)
    avis.dossier = dossier

    gestionnaire = Gestionnaire.find_by(email: create_params[:email])
    if gestionnaire
      avis.gestionnaire = gestionnaire
      avis.email = nil
    end

    avis.save

    redirect_to backoffice_dossier_path(dossier)
  end

  def update
    if avis.update(update_params)
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
