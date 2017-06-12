class CommentaireSerializer < ActiveModel::Serializer
  attributes :email,
    :body,
    :created_at
end
