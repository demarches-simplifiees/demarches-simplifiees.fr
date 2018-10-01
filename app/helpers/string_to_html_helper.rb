module StringToHtmlHelper
  def string_to_html(str)
    html_formatted = simple_format(str)
    with_links = html_formatted.gsub(URI.regexp, '<a target="_blank" href="\0">\0</a>')
    sanitize(with_links, attributes: ['href', 'target'])
  end
end
