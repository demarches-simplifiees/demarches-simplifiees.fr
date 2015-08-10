class DemandesController < ApplicationController
  def show
    @dossier = Dossier.find(params[:dossier_id])
    @evenement_vie = EvenementVie.where(use_admi_facile: true)
  end

  def choice
    @dossier = Dossier.find(params[:dossier_id])
    @dossier.ref_formulaire = params[:ref_formulaire]
    @dossier.save

    redirect_to url_for({controller: :carte, action: :show, :dossier_id => params[:dossier_id]})
  end
end
