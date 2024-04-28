# frozen_string_literal: true

class String
  JSV_REGEX_SPECIAL_CHARS = /[\[\]\{\}"\,]/.freeze

  def to_jsv
    double_quoted = self.gsub('"', '""')
    if match?(JSV_REGEX_SPECIAL_CHARS)
      "\"#{double_quoted}\""
    else
      double_quoted
    end
  end
end
