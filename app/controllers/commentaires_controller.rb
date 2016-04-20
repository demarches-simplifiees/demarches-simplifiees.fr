class CommentairesController < ApplicationController
  def create
    @commentaire = Commentaire.new
    @commentaire.dossier = Dossier.find(params['dossier_id'])

    if is_gestionnaire?
      @commentaire.email = current_gestionnaire.email
      @commentaire.dossier.next_step! 'gestionnaire', 'comment'
    else
      @commentaire.email = current_user.email
      @commentaire.dossier.next_step! 'user', 'comment' if current_user.email == @commentaire.dossier.user.email
    end

    unless params[:piece_justificative].nil?
      pj = PiecesJustificativesService.upload_one! @commentaire.dossier, current_user, params

      if pj.errors.empty?
        @commentaire.piece_justificative = pj
      else
        flash.alert = pj.errors.full_messages.join("<br>").html_safe
      end
    end

    @commentaire.body = params['texte_commentaire']
    @commentaire.save unless flash.alert

    if is_gestionnaire?
      NotificationMailer.new_answer(@commentaire.dossier).deliver_now!
      redirect_to url_for(controller: 'backoffice/dossiers', action: :show, id: params['dossier_id'])
    elsif current_user.email != @commentaire.dossier.user.email
      invite = Invite.where(dossier: @commentaire.dossier, user: current_user).first
      redirect_to url_for(controller: 'users/dossiers/invites', action: :show, id: invite.id)
    else
      redirect_to url_for(controller: :recapitulatif, action: :show, dossier_id: params['dossier_id'])
    end
  end

  def is_gestionnaire?
    false
  end
end
