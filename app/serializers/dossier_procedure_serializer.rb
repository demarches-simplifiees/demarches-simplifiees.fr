class DossierProcedureSerializer < ActiveModel::Serializer
  attributes :id,
             :created_at,
             :updated_at,
             :archived,
             :mandataire_social,
             :state

  has_many :champs
end
