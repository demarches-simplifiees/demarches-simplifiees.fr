class DossiersSerializer < ActiveModel::Serializer
  attributes :id,
    :updated_at,
    :initiated_at
end
