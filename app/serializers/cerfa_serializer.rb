class CerfaSerializer < ActiveModel::Serializer

  attributes :created_at,
             :content_url => :url


end