class DossiersSerializer < ActiveModel::Serializer
  include DossierHelper

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
    dossier_legacy_state(object)
  end
end
