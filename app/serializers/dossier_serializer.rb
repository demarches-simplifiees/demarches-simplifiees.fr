class DossierSerializer < ActiveModel::Serializer
  attributes :id,
             :created_at,
             :updated_at,
             :archived,
             :mandataire_social,
             :state,
             :total_commentaire

  has_one :entreprise
  has_one :etablissement
  has_many :cerfa
  has_many :commentaires
  has_many :champs
  has_many :pieces_justificatives
  has_many :types_de_piece_justificative
end