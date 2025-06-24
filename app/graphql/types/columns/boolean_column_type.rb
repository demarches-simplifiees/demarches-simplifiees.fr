# frozen_string_literal: true

module Types::Columns
  class BooleanColumnType < Types::BaseObject
    implements Types::ColumnType

    field :value, Boolean, null: true, extras: [:parent]

    def value(parent:)
      object.value(parent)
    end
  end
end
