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
  has_one :cerfa
  has_many :champs
  has_many :pieces_justificatives
end