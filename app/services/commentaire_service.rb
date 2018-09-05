class CommentaireService
  class << self
    def create(sender, dossier, params)
      attributes = params.merge(email: sender.email, dossier: dossier)

      # If the user submits a empty message, simple_format will replace '' by '<p></p>',
      # and thus bypass the not-empty constraint on commentaire's body.
      #
      # To avoid this, format the message only if a body is present in the first place.
      if attributes[:body].present?
        attributes[:body] = ActionController::Base.helpers.simple_format(attributes[:body])
      end

      Commentaire.new(attributes)
    end
  end
end
