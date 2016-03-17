class TypeDePieceJustificativeSerializer < ActiveModel::Serializer
  attributes :id,
             :libelle,
             :description

  has_many :pieces_justificatives
end