# frozen_string_literal: true

module Types::Columns
  class DateTimeColumnType < Types::BaseObject
    implements Types::ColumnType

    field :value, GraphQL::Types::ISO8601DateTime, null: true, extras: [:parent]

    def value(parent:)
      object.value(parent)
    end
  end
end
