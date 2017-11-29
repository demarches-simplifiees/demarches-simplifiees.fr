class QuartierPrioritaireSerializer < ActiveModel::Serializer
  attributes :value, :type_de_champ

  def value
    object.geometry
  end

  def type_de_champ
    {
      id: -1,
      libelle: 'quartier prioritaire',
      type_champ: 'quartier_prioritaire',
      order_place: -1,
      descripton: ''
    }
  end
end
