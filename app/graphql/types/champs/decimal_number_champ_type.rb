# frozen_string_literal: true

module Types::Champs
  class DecimalNumberChampType < Types::BaseObject
    implements Types::ChampType

    field :value, Float, null: true

    def value
      if object.value.present?
        object.value.to_f
      end
    end
  end
end
