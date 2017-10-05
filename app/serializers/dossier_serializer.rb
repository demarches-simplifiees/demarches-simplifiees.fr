class DossierSerializer < ActiveModel::Serializer
  attributes :id,
    :created_at,
    :updated_at,
    :archived,
    :email,
    :mandataire_social,
    :state,
    :simplified_state,
    :initiated_at,
    :received_at,
    :processed_at,
    :motivation,
    :accompagnateurs,
    :invites

  has_one :entreprise
  has_one :etablissement
  has_many :cerfa
  has_many :commentaires
  has_many :champs
  has_many :champs_private
  has_many :pieces_justificatives
  has_many :types_de_piece_justificative

  def email
    object.user.try(:email)
  end

  def simplified_state
    object.decorate.display_state
  end

  def accompagnateurs
    object.followers_gestionnaires.pluck(:email)
  end

  def invites
    object.invites_gestionnaires.pluck(:email)
  end

  def commentaires
    object.commentaires.order(created_at: :asc)
  end
end
