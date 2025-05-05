# frozen_string_literal: true

module Sanitizers
  class Xml
    # matches any character that is not allowed in XML 1.0 character content : https://www.w3.org/TR/xml/#charsets
    #
    # | Code Point(s)            | Character(s)                | Description                                      |
    # |--------------------------|-----------------------------|--------------------------------------------------|
    # | `\u{9}`                  | TAB (`\t`)                  | Horizontal Tab                                   |
    # | `\u{A}`                  | LF (`\n`)                   | Line Feed (newline)                              |
    # | `\u{D}`                  | CR (`\r`)                   | Carriage Return                                  |
    # | `\u{20}-\u{D7FF}`        | Space to U+D7FF             | Most of the Basic Multilingual Plane (BMP)       |
    # | `\u{E000}-\u{FFFD}`      | Private Use Area to BMP end | Valid characters excluding non-characters        |

    # **Negated Set Explanation:**

    # This regexp uses `[^...]`, so it matches any character **not in** the allowed ranges above. That includes:

    # - Control characters except TAB, LF, CR
    # - Surrogate halves (`\u{D800}`–`\u{DFFF}`), which are invalid standalone
    # - Non-characters like `\u{FFFE}`, `\u{FFFF}`
    # - Characters above `\u{FFFD}` unless additional ranges are added

    # **Use Case:**

    # Filter out invalid XML characters when working with strings in Ruby before writing them to XML documents.
    INVALID_XML_CHARS = /[^\u{9}\u{A}\u{D}\u{20}-\u{D7FF}\u{E000}-\u{FFFD}]/u

    def self.sanitize(str)
      (str || "").to_s.gsub(INVALID_XML_CHARS, ' ')
    end
  end
end
