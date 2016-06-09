class TypeDePieceJustificativeSerializer < ActiveModel::Serializer
  attributes :id,
             :libelle,
             :description,
             :order_place
end