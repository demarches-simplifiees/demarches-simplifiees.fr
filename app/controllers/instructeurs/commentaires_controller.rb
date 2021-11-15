# frozen_string_literal: true

module Instructeurs
  class CommentairesController < ProceduresController

    def destroy
      result = CommentaireService.soft_delete(current_instructeur, params.permit(:dossier_id, :id))
      if result.status
        flash[:notice] = 'Votre message a été supprimé'
      else
        flash[:alert] = "Votre message ne peut être supprimé: #{result.error_message}"
      end
      redirect_to(messagerie_instructeur_dossier_path(params[:procedure_id], params[:dossier_id]))
    end
  end
end
