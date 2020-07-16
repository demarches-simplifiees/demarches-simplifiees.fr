module ContentTypeHelper
  def file_descriptions_from_content_types(content_types)
    content_types.map { |ct| CONTENT_TYPE_DESCRIPTIONS[ct] }.uniq.join(', ')
  end

  def file_extensions_from_content_types(content_types)
    content_types.map do |ct|
      if CONTENT_TYPE_EXTENSIONS.include?(ct)
        ".#{CONTENT_TYPE_EXTENSIONS[ct]}"
      end
    end.uniq.sort.join(', ')
  end

  CONTENT_TYPE_DESCRIPTIONS = {
    "text/plain" => 'Word',
    "application/pdf" => "PDF",
    "application/msword" => "Word",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "Excel",
    "application/vnd.ms-excel" => "Excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => "Excel",
    "application/vnd.ms-powerpoint" => "PowerPoint",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" => "PowerPoint",
    "application/vnd.oasis.opendocument.text" => "LibreOffice",
    "application/vnd.oasis.opendocument.presentation" => "LibreOffice",
    "application/vnd.oasis.opendocument.spreadsheet" => "LibreOffice",
    "image/png" => "PNG",
    "image/jpeg" => "JPG"
  }

  #  Mapping between format and extension documented on MDN:
  # https://developer.mozilla.org/fr/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
  CONTENT_TYPE_EXTENSIONS = {
    "text/plain" => "txt",
    "application/pdf" => "pdf",
    "application/msword" => "doc",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "docx",
    "application/vnd.ms-excel" => "xls",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => "xlsx",
    "application/vnd.ms-powerpoint" => "ppt",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" => "pptx",
    "application/vnd.oasis.opendocument.text" => "odt",
    "application/vnd.oasis.opendocument.presentation" => "odp",
    "application/vnd.oasis.opendocument.spreadsheet" => "ods",
    "image/png" => "png",
    "image/jpeg" => "jpg"
  }
end
