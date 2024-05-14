# frozen_string_literal: true

class Hash
  def to_jsv
    js_array = filter_map do |key, value|
      next if value.nil? # skip nil values

      "#{key.to_jsv}:#{value.to_jsv}"
    end

    "{" + js_array.join(",") + "}"
  end
end
