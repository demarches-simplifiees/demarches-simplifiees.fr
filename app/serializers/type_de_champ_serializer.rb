class TypeDeChampSerializer < ActiveModel::Serializer
  attributes :id,
             :libelle,
             :type_champ,
             :order_place,
             :description
end
