class DossiersSerializer < ActiveModel::Serializer
  attributes :id,
    :updated_at,
    :initiated_at,
    :state

  def updated_at
    object.updated_at&.in_time_zone('UTC')
  end

  def initiated_at
    object.en_construction_at&.in_time_zone('UTC')
  end

  def state
    object.old_state_value
  end
end
