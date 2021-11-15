# frozen_string_literal: true

module Instructeurs
  class CommentairesController < ProceduresController

    def destroy
      result = CommentaireService.soft_delete(current_instructeur, params.permit(:dossier_id, :commentaire_id))
      if result.status
        flash_message = { notice: 'Votre commentaire a bien été supprimé' }
      else
        flash_message = { error: "Votre commentaire ne peut être supprimé: #{result.error_messages}" }
      end
      redirect_to(messagerie_instructeur_dossier_path(params[:procedure_id], params[:dossier_id]),
                  flash: flash_message)
    end
  end
end
