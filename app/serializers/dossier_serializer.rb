class DossierSerializer < ActiveModel::Serializer
  attributes :id,
             :nom_projet,
             :description,
             :created_at,
             :updated_at,
             :archived

  has_one :entreprise
  has_one :etablissement
end