class DossiersSerializer < ActiveModel::Serializer
  attributes :id,
    :updated_at,
    :initiated_at,
    :state

  def initiated_at
    object.en_construction_at
  end

  def state
    object.old_state_value
  end
end
