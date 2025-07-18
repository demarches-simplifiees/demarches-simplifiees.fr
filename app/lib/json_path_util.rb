# frozen_string_literal: true

# Extension de la classe JsonPath de la gem
class JSONPathUtil
  def self.array_paths_with_examples(hash, parent_path = '$')
    hash.each_with_object({}) do |(key, value), result|
      current_path = "#{parent_path}.#{key}"

      case value
      in [Hash => first, *]
        result.merge!(current_path => first)
      in Hash
        nested = array_paths_with_examples(value, current_path)
        result.merge!(nested)
      else
        result
      end
    end
  end

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
end
