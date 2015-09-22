class CommentairesController < ApplicationController
  def create
    @commentaire = Commentaire.new
    @commentaire.email = params['email_commentaire']
    @commentaire.body = params['texte_commentaire']
    @commentaire.dossier = Dossier.find(params['dossier_id'])

    @commentaire.save

    if is_gestionnaire?
      redirect_to url_for(controller: 'backoffice/dossiers', action: :show, id: params['dossier_id'])
    else
      redirect_to url_for(controller: :recapitulatif, action: :show, dossier_id: params['dossier_id'])
    end
  end

  def is_gestionnaire?
    false
  end
end
