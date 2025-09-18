# frozen_string_literal: true

class SortedColumnType < ActiveRecord::Type::Value
  # form_input or setter -> type
  def cast(value)
    value = value.deep_symbolize_keys if value.respond_to?(:deep_symbolize_keys)

    case value
    in SortedColumn
      value
    in NilClass # default value
      nil
    # from form (id is a string) or from db (id is a hash)
    in { order: 'asc' | 'desc', id: String | Hash } => h
      SortedColumn.new(column: ColumnType.new.cast(h[:id]), order: h[:order])
    end
  end

  # db -> ruby
  def deserialize(value) = cast(value&.then { JSON.parse(_1) })

  # ruby -> db
  def serialize(value)
    case value
    in NilClass
      nil
    in SortedColumn
      JSON.generate({
        id: value.column.h_id,
        order: value.order
      })
    else
      raise ArgumentError, "Invalid value for SortedColumn serialization: #{value}"
    end
  end
end
