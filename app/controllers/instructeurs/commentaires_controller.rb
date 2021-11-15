# frozen_string_literal: true

module Instructeurs
  class CommentairesController < ProceduresController
    def destroy
      result = CommentaireService.soft_delete(current_instructeur, params.permit(:dossier_id, :id))
      if result.status
        flash[:notice] = t('views.shared.commentaires.destroy.notice')
      else
        flash[:alert] = t('views.shared.commentaires.destroy.alert', reason: result.error_message)
      end
      redirect_to(messagerie_instructeur_dossier_path(params[:procedure_id], params[:dossier_id]))
    end
  end
end
