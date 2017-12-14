class DossiersSerializer < ActiveModel::Serializer
  attributes :id,
    :updated_at,
    :initiated_at

  def initiated_at
    object.en_construction_at
  end
end
