class CommentairesController < ApplicationController
  def create
    @commentaire = Commentaire.new
    @commentaire.dossier = Dossier.find(params['dossier_id'])

    if is_gestionnaire?
      @commentaire.email = current_gestionnaire.email
      @commentaire.dossier.next_step! 'gestionnaire', 'comment'
    else #is_user
      @commentaire.email = current_user.email
      @commentaire.dossier.next_step! 'user', 'comment'
    end

    @commentaire.body = params['texte_commentaire']
    @commentaire.save

    if is_gestionnaire?
      NotificationMailer.new_answer(@commentaire.dossier).deliver_now!
      redirect_to url_for(controller: 'backoffice/dossiers', action: :show, id: params['dossier_id'])
    else
      redirect_to url_for(controller: :recapitulatif, action: :show, dossier_id: params['dossier_id'])
    end
  end

  def is_gestionnaire?
    false
  end
end
