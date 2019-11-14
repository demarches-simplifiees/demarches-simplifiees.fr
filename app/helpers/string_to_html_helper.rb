module StringToHtmlHelper
  def string_to_html(str, wrapper_tag = 'p')
    html_formatted = simple_format(str, {}, { wrapper_tag: wrapper_tag })
    with_links = html_formatted.gsub(URI.regexp, '<a target="_blank" rel="noopener" href="\0">\0</a>')
    sanitize(with_links, attributes: ['target', 'rel', 'href'])
  end
end
