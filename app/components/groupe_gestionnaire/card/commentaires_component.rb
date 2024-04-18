class GroupeGestionnaire::Card::CommentairesComponent < ApplicationComponent
  def initialize(groupe_gestionnaire:, administrateur:, path:, unread_commentaires: nil)
    @groupe_gestionnaire = groupe_gestionnaire
    @administrateur = administrateur
    @path = path
    @unread_commentaires = unread_commentaires
  end

  def number_commentaires
    if @administrateur
      @administrateur.commentaire_groupe_gestionnaires.size
    else
      commentaires = @groupe_gestionnaire.current_commentaires_groupe_and_children_commentaires_groupe
      if @groupe_gestionnaire.parent_id && !current_gestionnaire.groupe_gestionnaires.exists?(id: @groupe_gestionnaire.parent_id)
        commentaires = commentaires.or(CommentaireGroupeGestionnaire.where(groupe_gestionnaire_id: @groupe_gestionnaire.id, sender: current_gestionnaire))
      end
      commentaires.select(:sender_id, :sender_type).distinct.size
    end
  end
end
