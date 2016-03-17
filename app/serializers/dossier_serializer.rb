class DossierSerializer < ActiveModel::Serializer
  attributes :id,
             :nom_projet,
             :description,
             :created_at,
             :updated_at,
             :archived,
             :mandataire_social

  has_one :entreprise
  has_one :etablissement
  has_many :cerfa
  has_many :commentaires
  has_many :champs
  has_many :types_de_piece_justificative
end