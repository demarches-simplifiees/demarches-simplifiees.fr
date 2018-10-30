class CommentaireSerializer < ActiveModel::Serializer
  attributes :email,
    :body,
    :created_at,
    :attachment

  def attachment
    object.file_url
  end
end
