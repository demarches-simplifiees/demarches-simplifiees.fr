module StringToHtmlHelper
  def string_to_html(str, wrapper_tag = 'p')
    tags = ['a', 'abbr', 'acronym', 'address', 'b', 'big', 'blockquote', 'br', 'cite', 'code', 'dd', 'del', 'dfn', 'div', 'dl', 'dt', 'em', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'i', 'img', 'ins', 'kbd', 'li', 'ol', 'p', 'pre', 'samp', 'small', 'span', 'sub', 'sup', 'table', 'td', 'th', 'tr', 'tt', 'u', 'ul', 'var', 'strong']
    atts = ['target', 'rel', 'href', 'class', 'src', 'alt', 'width', 'height']
    html_formatted = "<#{wrapper_tag}>" + str.to_s.gsub(/(?<=[^>])\r?\n/, "\n<br>") + "</#{wrapper_tag}>"
    # html_formatted = simple_format(str, {}, { wrapper_tag: wrapper_tag })
    uri_regexp = /(?<!["\'])#{URI.regexp(['https', 'http', 'ftp', 'mailto']).source}/x
    with_links = html_formatted.gsub(uri_regexp, '<a target="_blank" rel="noopener" href="\0">\0</a>')
    sanitize(with_links, tags: tags, attributes: atts)
  end
end
