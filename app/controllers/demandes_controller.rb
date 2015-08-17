class DemandesController < ApplicationController
  def show
    @dossier = Dossier.find(params[:dossier_id])
    @evenements_vie = EvenementVie.for_admi_facile
  end

  def update
    @dossier = Dossier.find(params[:dossier_id])
    @dossier.update_attributes(formulaire_id: params[:formulaire])

    redirect_to url_for(controller: :carte, action: :show, dossier_id: params[:dossier_id])
  end

end
