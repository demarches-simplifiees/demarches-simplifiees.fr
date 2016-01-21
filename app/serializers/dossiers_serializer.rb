class DossiersSerializer < ActiveModel::Serializer
  attributes :id,
             :nom_projet,
             :updated_at
end