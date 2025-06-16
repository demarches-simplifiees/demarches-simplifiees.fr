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
      .transform_keys { jsonpath_to_simili(it) }
  end

  # posting real json path to controller is interpreted as nested hashes
  # ie : repetition[0].field_name becomes
  # {
  #   "repetition": [
  #     { "field_name": "value" }
  #   ]
  # }
  # In case of deeply nested structure it becomes a pain to handle with StrongParameters
  # So we rewrite the jsonpath to avoid this
  def self.jsonpath_to_simili(jsonpath)
    jsonpath.tr('[', '{').tr(']', '}')
  end

  def self.simili_to_jsonpath(jsonpath)
    jsonpath.tr('{', '[').tr('}', ']')
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
