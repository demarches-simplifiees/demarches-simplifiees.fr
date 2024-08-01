module Types::Champs
  class NumbersIdChampType < Types::BaseObject
    implements Types::ChampType

    field :value, String, null: true

    def value
      (object.value.presence)
    end
  end
end
