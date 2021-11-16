# frozen_string_literal: true

module Instructeurs
  class CommentairesController < ProceduresController
    def destroy
      commentaire = Dossier.find(params[:dossier_id]).commentaires.find(params[:id])
      if commentaire.sent_by?(current_instructeur)
        commentaire.piece_jointe.purge_later if commentaire.piece_jointe.attached?
        commentaire.discard!
        commentaire.update!(body: '')
        flash[:notice] = t('views.shared.commentaires.destroy.notice')
      else
        flash[:alert] = I18n.t('views.shared.commentaires.destroy.alert_reasons.acl')
      end
      redirect_to(messagerie_instructeur_dossier_path(params[:procedure_id], params[:dossier_id]))
    rescue Discard::RecordNotDiscarded
      flash[:alert] = I18n.t('views.shared.commentaires.destroy.alert_reasons.already_discarded')
      redirect_to(messagerie_instructeur_dossier_path(params[:procedure_id], params[:dossier_id]))
    end
  end
end
