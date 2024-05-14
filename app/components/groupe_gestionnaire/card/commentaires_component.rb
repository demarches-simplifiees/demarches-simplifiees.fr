# frozen_string_literal: true

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
      @groupe_gestionnaire.gestionnaire_commentaires(current_gestionnaire)
        .select(:sender_id, :sender_type)
        .distinct.size
    end
  end
end
