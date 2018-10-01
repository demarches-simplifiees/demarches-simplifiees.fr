class CommentairesController < ApplicationController
  def create
    @commentaire = Commentaire.new

    if params[:champ_id]
      @commentaire.champ = @commentaire.dossier.champs.find(params[:champ_id])
    end

    dossier_id = params['dossier_id']
    @commentaire.email = current_user.email
    @commentaire.dossier = current_user.dossiers.find_by(id: dossier_id) || current_user.invites.find_by!(dossier_id: dossier_id).dossier

    @commentaire.file = params["file"]

    @commentaire.body = params['texte_commentaire']
    if @commentaire.save
      flash.notice = "Votre message a été envoyé"
    else
      flash.alert = "Veuillez rédiger un message ou ajouter une pièce jointe (maximum 20 Mo)"
    end

    if current_user.email != @commentaire.dossier.user.email
      invite = Invite.where(dossier: @commentaire.dossier, email: current_user.email).first
      redirect_to url_for(controller: 'users/dossiers/invites', action: :show, id: invite.id)
    else
      redirect_to users_dossier_recapitulatif_path(params['dossier_id'])
    end
  end
end
