class CadastreSerializer < ActiveModel::Serializer
  attributes :value, :type_de_champ

  def value
    object.geometry
  end

  def type_de_champ
    {
      id: -1,
      libelle: 'cadastre',
      type_champ: 'cadastre',
      order_place: -1,
      descripton: ''
    }
  end
end
