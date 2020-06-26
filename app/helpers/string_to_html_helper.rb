module StringToHtmlHelper
  def string_to_html(str, wrapper_tag = 'p')
    tags = ['a', 'abbr', 'acronym', 'address', 'b', 'big', 'blockquote', 'br', 'cite', 'code', 'dd', 'del', 'dfn', 'div', 'dl', 'dt', 'em', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'i', 'img', 'ins', 'kbd', 'li', 'ol', 'p', 'pre', 'samp', 'small', 'span', 'sub', 'sup', 'table', 'td', 'th', 'tr', 'tt', 'u', 'ul', 'var', 'strong']
    atts = ['target', 'rel', 'href', 'class', 'src', 'alt', 'width', 'height']
    html_formatted = "<#{wrapper_tag}>" + str.to_s.gsub(/(?<![>\r])\r?\n/, "\n<br>") + "</#{wrapper_tag}>"
    with_links = Anchored::Linker.auto_link(html_formatted, target: '_blank', rel: 'noopener')
    sanitize(with_links, tags: tags, attributes: atts)
  end
end
