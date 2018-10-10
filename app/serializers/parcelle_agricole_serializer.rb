class ParcelleAgricoleSerializer < ActiveModel::Serializer
  attributes :value, :type_de_champ

  def value
    object.geometry
  end

  def type_de_champ
    {
      id: -1,
      libelle: 'parcelle agricole',
      type_champ: 'parcelle_agricole',
      order_place: -1,
      descripton: ''
    }
  end
end
