class PieceJustificativeSerializer < ActiveModel::Serializer
  attributes :created_at,
    :type_de_piece_justificative_id,
    :content_url

  has_one :user
end
