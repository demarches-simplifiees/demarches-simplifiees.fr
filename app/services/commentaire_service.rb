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
      if !dossier.messagerie_available?
        raise ArgumentError, "Commentaires cannot be added to brouillons or archived Dossiers"
      end
      attributes = params.merge(email: email, dossier: dossier)
      Commentaire.new(attributes)
    end
  end
end
