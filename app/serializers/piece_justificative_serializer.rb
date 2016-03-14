class PieceJustificativeSerializer < ActiveModel::Serializer
  attributes :created_at,
             :content_url => :url

  has_one :type_de_piece_justificative
end