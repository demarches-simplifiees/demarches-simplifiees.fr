# frozen_string_literal: true

class GroupeGestionnaire < ApplicationRecord
  has_many :administrateurs
  has_many :commentaire_groupe_gestionnaires
  has_many :follow_commentaire_groupe_gestionnaires
  has_and_belongs_to_many :gestionnaires

  has_ancestry

  def add_gestionnaire(gestionnaire)
    return if gestionnaire.nil?
    return if in?(gestionnaire.groupe_gestionnaires)

    gestionnaires << gestionnaire
  end

  def add_administrateur(administrateur)
    return if administrateur.nil?
    return if id == administrateur.groupe_gestionnaire_id

    administrateurs << administrateur
  end

  def can_be_deleted?(current_user)
    (gestionnaires.empty? || (gestionnaires == [current_user])) && administrateurs.empty? && children.empty?
  end

  def parent_name
    parent&.name
  end

  def current_commentaires_groupe_and_children_commentaires_groupe
    commentaires = CommentaireGroupeGestionnaire.where(groupe_gestionnaire_id: id, sender_type: "Administrateur")
    unless child_ids.empty?
      commentaires = commentaires.or(CommentaireGroupeGestionnaire.where(groupe_gestionnaire_id: child_ids, sender_type: "Gestionnaire"))
    end
    commentaires
  end

  def gestionnaire_commentaires(gestionnaire)
    commentaires = self.current_commentaires_groupe_and_children_commentaires_groupe
    if self.parent_id && !gestionnaire.groupe_gestionnaires.exists?(id: self.parent_id)
      commentaires = commentaires.or(CommentaireGroupeGestionnaire.where(groupe_gestionnaire_id: self.id, sender: gestionnaire))
    end
    commentaires
  end
end
