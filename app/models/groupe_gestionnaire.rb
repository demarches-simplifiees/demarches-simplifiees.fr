class GroupeGestionnaire < ApplicationRecord
  has_many :administrateurs
  has_many :commentaire_groupe_gestionnaires
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

  def can_be_deleted?(current_user)
    (gestionnaires.empty? || (gestionnaires == [current_user]))&& administrateurs.empty? && children.empty?
  end
end
