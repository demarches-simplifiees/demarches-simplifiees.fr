module Types::Champs
  class NumbersAndLettersIdChampType < Types::BaseObject
    implements Types::ChampType

    field :value, String, null: true

    def value
      (object.value.presence)
    end
  end
end
