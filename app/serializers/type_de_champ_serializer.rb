class TypeDeChampSerializer < ActiveModel::Serializer
  attributes :id,
    :libelle,
    :type_champ,
    :order_place,
    :description

  def id
    object.stable_id || object.id
  end
end
