class RecapitulatifController < ApplicationController
  def show
    @dossier = Dossier.find(params[:dossier_id])
    @dossier = @dossier.decorate

    # mettre dans le modele
    @commentaires = @dossier.commentaires.order(created_at: :desc)

    @commentaires = @commentaires.all.decorate

    #TODO load user email
    @commentaire_email = 'user@email'
  rescue ActiveRecord::RecordNotFound
    redirect_to url_for(controller: :start, action: :error_dossier)
  end
end
