class ChampSerializer < ActiveModel::Serializer
  attributes :value

  has_one :type_de_champ
end
