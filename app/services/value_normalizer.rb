# frozen_string_literal: true

class ValueNormalizer
  # Regex to detect invisible ASCII control characters
  # that can cause problems in string processing
  # Matches the following characters:
  # - \u0000-\u0008: control characters NUL, SOH, STX, ETX, EOT, ENQ, ACK, BEL
  # - \u000B: VT character (Vertical Tab)
  # - \u000C: FF character (Form Feed)
  # - \u000E-\u001F: control characters SO, SI, DLE, DC1, DC2, DC3, DC4, NAK, SYN, ETB, CAN, EM, SUB, ESC, FS, GS, RS, US
  # - \u007F: DEL character (Delete)
  CONTROL_CHARS_REGEX = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/.freeze

  class << self
    def normalize(input)
      case input
      when Array
        input.map { normalize(_1) }
      when Hash
        input.transform_values { normalize(_1) }
      else
        normalize_string(input)
      end
    end

    private

    def normalize_string(str)
      return str if str.nil?

      coerced = str.to_s
      coerced = coerced.gsub(/\r\n?/, "\n")
      coerced.gsub(CONTROL_CHARS_REGEX, "")
    end
  end
end
