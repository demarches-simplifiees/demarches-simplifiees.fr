# frozen_string_literal: true

class JSONPathUtil
  def self.filter_selectable_datasources(json, parent_path = '$')
    if json.is_a?(Hash)
      json.each_with_object({}) do |(key, value), result|
        json_path = "#{parent_path}.#{key}"

        case value
        in [Hash => first, *] => suggestions
          result.merge!(json_path => suggestions)
        in Hash
          nested = filter_selectable_datasources(value, json_path)
          result.merge!(nested)
        else
          result
        end
      end
    elsif json.is_a?(Array)
      { "#{parent_path}." => json }
    else
      {}
    end
  end

  def self.hash_to_jsonpath(json, parent_path = '$')
    if json.is_a?(Hash)
      json.each_with_object({}) do |(key, value), result|
        current_path = "#{parent_path}.#{key}"

        case value
        in Hash
          result.merge!(hash_to_jsonpath(value, current_path))
        in [Hash => first, *]
          result.merge!(hash_to_jsonpath(first, "#{current_path}[0]"))
        else
          result[current_path] = value
        end
      end
    elsif json.is_a?(Array)
      hash_to_jsonpath(json.first, "#{parent_path}.[0]")
    else
      {}
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
