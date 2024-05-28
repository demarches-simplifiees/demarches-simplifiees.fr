# frozen_string_literal: true

def header_value(name, message)
  message.header.fields.find { _1.name == name }.value
end
