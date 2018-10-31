class PieceJustificativeSerializer < ActiveModel::Serializer
  attributes :created_at,
    :type_de_piece_justificative_id,
    :content_url

  has_one :user

  def created_at
    object.created_at&.in_time_zone('UTC')
  end
end
