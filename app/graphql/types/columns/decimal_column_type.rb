# frozen_string_literal: true

module Types::Columns
  class DecimalColumnType < Types::BaseObject
    implements Types::ColumnType

    field :value, Float, null: true, extras: [:parent]

    def value(parent:)
      object.value(parent)
    end
  end
end
