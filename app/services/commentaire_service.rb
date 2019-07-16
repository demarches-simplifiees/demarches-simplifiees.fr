class CommentaireService
  class << self
    def build(sender, dossier, params)
      case sender
      when User
        params[:user] = sender
      when Gestionnaire
        params[:gestionnaire] = sender
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
  end
end
