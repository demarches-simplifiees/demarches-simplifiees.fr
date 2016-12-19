class CerfaSerializer < ActiveModel::Serializer
  attributes :created_at,
             :content_url

  has_one :user
end