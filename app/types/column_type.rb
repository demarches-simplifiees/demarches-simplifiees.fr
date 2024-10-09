# frozen_string_literal: true

class ColumnType < ActiveRecord::Type::Value
  # value can come from:
  # setter: column (Column),
  # form_input: column.id == { procedure_id:, column_id: }.to_json (String),
  # from db: { procedure_id:, column_id: } (Hash)
  def cast(value)
    case value
    in NilClass
      nil
    in Column
      value
    # from form
    in String => id
      h_id = JSON.parse(id, symbolize_names: true)
      Column.find(h_id)
    # from db
    in Hash => h_id
      Column.find(h_id)
    end
  end

  # db -> ruby
  def deserialize(value) = cast(value)

  # ruby -> db
  def serialize(value)
    case value
    in NilClass
      nil
    in Column
      JSON.generate(value.h_id)
    else
      raise ArgumentError, "Invalid value for Column serialization: #{value}"
    end
  end
end
