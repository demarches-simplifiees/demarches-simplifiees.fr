class CommentaireSerializer < ActiveModel::Serializer
  attributes :email,
    :body,
    :created_at,
    :piece_jointe_attachments

  def created_at
    object.created_at&.in_time_zone('UTC')
  end
end
