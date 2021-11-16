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
        commentaire.piece_jointe.purge_later if commentaire.piece_jointe.attached?
        commentaire.body = ''
        OpenStruct.new(status: commentaire.discard, error_message: commentaire.errors.full_messages.join(', '))
      else
        OpenStruct.new(status: false,
                       error_message: I18n.t('views.shared.commentaires.destroy.alert_reasons.acl'))
      end
    rescue ActiveRecord::RecordNotFound => e
      return OpenStruct.new(status: false,
                            error_message: I18n.t('views.shared.commentaires.destroy.alert_reasons.ar_not_found', model_name: e.model.humanize))
    end
  end
end
