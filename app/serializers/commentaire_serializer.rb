class CommentaireSerializer < ActiveModel::Serializer
  attributes :email,
    :body,
    :created_at,
    :attachment

  def created_at
    object.created_at&.in_time_zone('UTC')
  end

  def attachment
    object.file_url
  end
end
