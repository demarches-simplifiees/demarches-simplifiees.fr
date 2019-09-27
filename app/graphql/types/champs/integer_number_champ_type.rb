module Types::Champs
  class IntegerNumberChampType < Types::BaseObject
    implements Types::ChampType

    field :value, Int, null: true

    def value
      if object.value.present?
        object.value.to_i
      end
    end
  end
end
