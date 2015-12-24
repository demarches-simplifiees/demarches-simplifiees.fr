class ProcedureSerializer < ActiveModel::Serializer
  attributes :id,
             :libelle,
             :description,
             :organisation,
             :direction,
             :lien_demarche,
             :archived
  has_many :types_de_champ,  serializer: TypeDeChampSerializer
  has_many :types_de_piece_justificative,  serializer: TypeDePieceJustificativeSerializer
end
