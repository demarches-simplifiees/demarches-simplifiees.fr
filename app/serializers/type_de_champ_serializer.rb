class TypeDeChampSerializer < ActiveModel::Serializer
  attributes :id,
             :libelle,
             {:type_champ => :type},
             :order_place,
             :description
end