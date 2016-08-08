class ProcedureSerializer < ActiveModel::Serializer
  attribute :libelle, key: :label
  attribute :lien_demarche, key: :link

  attributes :id,
             :description,
             :organisation,
             :direction,
             :archived,
             :geographic_information,
             :total_dossier


  has_one :geographic_information, serializer: ModuleApiCartoSerializer
  has_many :types_de_champ, serializer: TypeDeChampSerializer
  has_many :types_de_champ_private, serializer: TypeDeChampSerializer
  has_many :types_de_piece_justificative, serializer: TypeDePieceJustificativeSerializer
end
