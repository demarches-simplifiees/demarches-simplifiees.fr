# frozen_string_literal: true

class JSONPathUtil
  SCHEMER = JSONSchemer.schema(Rails.root.join('app/schemas/geojson.json'))

  def self.hash_to_jsonpath(hash, parent_path = '$')
    hash.each_with_object({}) do |(key, value), result|
      current_path = "#{parent_path}.#{key}"
      value = value&.transform_keys(&:to_sym) if value.is_a?(Hash)
      case value
      in { type: String } if SCHEMER.valid?(value)
        result[current_path] = value
      in Hash
        result.merge!(hash_to_jsonpath(value, current_path))
      in [Hash => first, *]
        result.merge!(hash_to_jsonpath(first, "#{current_path}[0]"))
      else
        result[current_path] = value
      end
    end
  end

  # navigation
  def self.extract_array_name(str)
    str[/^[^\[]+/]
  end

  def self.extract_key_after_array(str)
    str[/\[(.*?)\](.*)/, 2]
  end
end
