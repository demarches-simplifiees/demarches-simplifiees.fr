module Types::Champs
  class RoutageChampType < Types::BaseObject
    implements Types::ChampType

    field :value, String, null: true
  end
end
