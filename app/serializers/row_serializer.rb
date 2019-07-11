class RowSerializer < ActiveModel::Serializer
  has_many :champs, serializer: ChampSerializer

  attribute :index, key: :id
end
