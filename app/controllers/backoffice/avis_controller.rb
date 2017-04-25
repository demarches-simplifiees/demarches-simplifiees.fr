class Backoffice::AvisController < ApplicationController

  def create
    avis = Avis.new(create_params)
    avis.dossier = dossier
    avis.save

    redirect_to backoffice_dossier_path(dossier)
  end

  private

  def dossier
    current_gestionnaire.dossiers.find(params[:dossier_id])
  end

  def create_params
    params.require(:avis).permit(:email, :introduction)
  end

end
