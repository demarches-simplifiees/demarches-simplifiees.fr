module Dolist
  Base64File = Struct.new(:field_name, :filename, :mime_type, :content, keyword_init: true)
end
