# frozen_string_literal: true

class JSONPath
  def self.hash_to_jsonpath(hash, parent_path = '$')
    hash.each_with_object({}) do |(key, value), result|
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
  end

  # navigation
  def self.extract_array_name(str)
    str[/^[^\[]+/]
  end

  def self.extract_key_after_array(str)
    str[/\[(.*?)\](.*)/, 2]
  end

  # getters
  def self.value(hash, jsonpath)
    hash&.dig(*jsonpath.split('.')[1..])
  end

  def self.get_array(hash, array_path)
    root_path = extract_array_name(array_path)
    value(hash, root_path)
  end
end
