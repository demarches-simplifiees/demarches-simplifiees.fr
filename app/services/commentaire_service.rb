class CommentaireService
  class << self
    def build(sender, dossier, params)
      case sender
      when Instructeur
        params[:instructeur] = sender
      when Expert
        params[:expert] = sender
      end

      build_with_email(sender.email, dossier, params)
    end

    def build_with_email(email, dossier, params)
      attributes = params.merge(email: email, dossier: dossier)
      # For some reason ActiveStorage trows an error in tests if we passe an empty string here.
      # I suspect it could be resolved in rails 6 by using explicit `attach()`
      if attributes[:piece_jointe].blank?
        attributes.delete(:piece_jointe)
      end
      Commentaire.new(attributes)
    end

    def soft_delete(user, params)
      commentaire = Dossier.find(params[:dossier_id])
                           .commentaires
                           .find(params[:id])
      if commentaire.sent_by?(user)
        commentaire.piece_jointe.purge_later  if commentaire.piece_jointe.attached?
        commentaire.update!(body: "Message supprimé", deleted_at: Time.now.utc)
        OpenStruct.new(status: true)
      else
        OpenStruct.new(status: false, error_message: "Impossible de supprimer le message, celui ci ne vous appartient pas")
      end
    rescue ActiveRecord::RecordNotFound => e
      return OpenStruct.new(status: false, error_message: "#{e.model.humanize} introuvable")
    end
  end
end
