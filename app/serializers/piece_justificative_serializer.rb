class PieceJustificativeSerializer < ActiveModel::Serializer
  attributes :content_url => :url

  has_one :type_de_piece_justificative
end