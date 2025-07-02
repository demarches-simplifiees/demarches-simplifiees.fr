# frozen_string_literal: true

module Types::Columns
  class IntegerColumnType < Types::BaseObject
    implements Types::ColumnType

    field :value, Int, null: true, extras: [:parent]

    def value(parent:)
      object.value(parent)
    end
  end
end
