class DeletedDossierSerializer < ActiveModel::Serializer
  attributes :id,
    :procedure_id,
    :state,
    :deleted_at

  def id
    object.dossier_id
  end

  def deleted_at
    object.deleted_at.in_time_zone('UTC')
  end
end
