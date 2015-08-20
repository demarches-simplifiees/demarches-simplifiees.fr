class CommentairesController < ApplicationController
  def create
    @commentaire = Commentaire.new
    @commentaire.email = params['email_commentaire']
    @commentaire.body = params['texte_commentaire']
    @commentaire.dossier = Dossier.find(params['dossier_id'])

    @commentaire.save

    if request.referer.include? '/recapitulatif'
      redirect_to url_for({controller: :recapitulatif, action: :show, :dossier_id => params['dossier_id']})
    else
      redirect_to url_for({controller: 'admin/dossier', action: :show, :dossier_id => params['dossier_id']})
    end
  end
end
