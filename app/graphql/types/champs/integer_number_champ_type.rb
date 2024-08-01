# frozen_string_literal: true

module Types::Champs
  class IntegerNumberChampType < Types::BaseObject
    implements Types::ChampType

    field :value, GraphQL::Types::BigInt, null: true

    def value
      if object.value.present?
        object.value.to_i
      end
    end
  end
end
