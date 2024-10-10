# frozen_string_literal: true

class FilteredColumnType < ActiveRecord::Type::Value
  # form_input or setter -> type
  def cast(value)
    value = value.deep_symbolize_keys if value.respond_to?(:deep_symbolize_keys)

    case value
    in FilteredColumn
      value
    in NilClass # default value
      nil
    # from form
    in { id: String|Hash, filter: String } => h
      FilteredColumn.new(column: ColumnType.new.cast(h[:id]), filter: h[:filter])
    end
  end

  # db -> ruby
  def deserialize(value) = cast(value&.then { JSON.parse(_1) })

  # ruby -> db
  def serialize(value)
    case value
    in NilClass
      nil
    in FilteredColumn
      JSON.generate({
        id: value.column.h_id,
        filter: value.filter
      })
    else
      raise ArgumentError, "Invalid value for FilteredColumn serialization: #{value}"
    end
  end
end
