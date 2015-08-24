class DemandesController < ApplicationController
  def show
    @dossier = Dossier.find(params[:dossier_id])
    @evenements_vie = EvenementVie.for_admi_facile
  end

  def update
    dossier = Dossier.find(params[:dossier_id])
    unless dossier.formulaire.nil?
      # TODO: redirect to start with an error message
      fail "La modification du formulaire n'est pas possible"
    end
    dossier.update_attributes(formulaire_id: params[:formulaire])
    redirect_to url_for(controller: :carte, action: :show, dossier_id: params[:dossier_id])
  end
end
