# frozen_string_literal: true

module Types::Columns
  class EnumColumnType < Types::BaseObject
    implements Types::ColumnType

    field :value, String, null: true, extras: [:parent]

    def value(parent:)
      object.value(parent)
    end
  end
end
