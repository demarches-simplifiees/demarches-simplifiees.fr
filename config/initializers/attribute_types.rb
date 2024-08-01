# frozen_string_literal: true

class SimpleJsonType < ActiveModel::Type::Value
  def cast(value)
    return nil if value.blank?
    return value if value.is_a?(Hash)
    JSON.parse(value)
  rescue JSON::ParserError
    {}
  end
end

ActiveModel::Type.register(:simple_json, SimpleJsonType)
