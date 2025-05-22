# frozen_string_literal: true

class ExternalDataExceptionType < ActiveRecord::Type::Value
  # value can come from:
  # setter: ExternalDataException or { reason:, code: } (Hash),
  # from db: { reason:, code: } (Hash)
  def cast(value)
    case value
    in NilClass
      nil
    in ExternalDataException
      value
    in { reason: String => reason, code: Integer => code}
      ExternalDataException.new(reason:, code:)
    in String => json_string
      h = JSON.parse(json_string, symbolize_names: true) rescue { reason: json_string, code: nil }
      ExternalDataException.new(reason: h[:reason], code: h[:code])
    else
      raise ArgumentError, "Invalid value for ExternalDataException casting: #{value}"
    end
  end

  # db -> ruby
  def deserialize(value) = cast(value)

  # ruby -> db
  def serialize(value)
    case value
    in NilClass
      nil
    in ExternalDataException
      JSON.generate({
        code: value.code,
        reason: value.reason
      })
    else
      raise ArgumentError, "Invalid value for ExternalDataException serialization: #{value}"
    end
  end
end
