class DossierProcedureSerializer < ActiveModel::Serializer
  attributes :id,
             :created_at,
             :updated_at,
             :archived,
             :mandataire_social,
             :state

  has_many :champs


  def champs
    object.champs.order("type_de_champ_id")
  end
end
