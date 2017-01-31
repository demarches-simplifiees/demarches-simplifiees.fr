class TypeDePieceJustificativeSerializer < ActiveModel::Serializer
  attributes :id,
             :libelle,
             :description,
             :order_place,
             :lien_demarche
end
