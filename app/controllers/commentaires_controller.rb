class CommentairesController < ApplicationController
  def index
    @facade = DossierFacades.new(
        params[:dossier_id],
        (current_gestionnaire || current_user).email,
        params[:champs_id]
    )
    render layout: false
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(controller: '/')
  end

  def create
    @commentaire = Commentaire.new
    @commentaire.dossier = Dossier.find(params['dossier_id'])
    @commentaire.champ = @commentaire.dossier.champs.find(params[:champ_id]) if params[:champ_id]

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
    saved = false
    unless @commentaire.body.blank? && @commentaire.piece_justificative.nil?
      saved = @commentaire.save unless flash.alert
    else
      flash.alert = "Veuillez rédiger un message ou ajouter une pièce jointe."
    end

    notify_user_with_mail(@commentaire)

    if is_gestionnaire?
      unless current_gestionnaire.follow? @commentaire.dossier
        current_gestionnaire.toggle_follow_dossier @commentaire.dossier
      end

      redirect_to url_for(controller: 'backoffice/dossiers', action: :show, id: params['dossier_id'])
    else
      if current_user.email != @commentaire.dossier.user.email
        invite = Invite.where(dossier: @commentaire.dossier, email: current_user.email).first
        redirect_to url_for(controller: 'users/dossiers/invites', action: :show, id: invite.id)
      else
        redirect_to users_dossier_recapitulatif_path(params['dossier_id'])
      end
    end
  end

  def is_gestionnaire?
    false
  end

  private

  def notify_user_with_mail(commentaire)
    NotificationMailer.new_answer(commentaire.dossier).deliver_now! unless current_user.email == commentaire.dossier.user.email
  end
end
