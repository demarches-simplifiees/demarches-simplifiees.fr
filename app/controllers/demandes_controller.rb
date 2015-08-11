class DemandesController < ApplicationController
  def show
    @dossier = Dossier.find(params[:dossier_id])
    @evenement_vie = EvenementVie.for_admi_facile
  end

  def choice
    @dossier = Dossier.find(params[:dossier_id])
    @dossier.update_attributes(ref_formulaire: params[:ref_formulaire])

    redirect_to url_for( { controller: :carte, action: :show, :dossier_id => params[:dossier_id] } )
  end
end
