class CerfaSerializer < ActiveModel::Serializer

  attributes :content_url => :url

  has_one :type_de_champ
end