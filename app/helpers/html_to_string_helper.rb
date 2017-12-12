module HtmlToStringHelper
  def html_to_string(html)
    if html.blank?
      html
    else
      string_with_tags = html
        .gsub(/<br[ ]?[\/]?>/, "\n")
        .gsub('</p>', "\n")
        .gsub('<p>', '')

      strip_tags(string_with_tags)
    end
  end
end
