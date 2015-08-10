class RecapitulatifController < ApplicationController
  def show
    @dossier = Dossier.find(params[:dossier_id])
    @dossier = @dossier.decorate

    @commentaires = @dossier.commentaires.order(created_at: :desc)
    @commentaires = @commentaires.all.decorate
    @commentaire_email = @dossier.mail_contact
  rescue
     redirect_to url_for({controller: :start, action: :error_dossier})
  end
end
