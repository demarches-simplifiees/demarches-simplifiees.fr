module StringToHtmlHelper
  def string_to_html(str, wrapper_tag = 'p')
    html_formatted = "<#{wrapper_tag}>" + str.to_s.gsub(/(?<![>\r])\r?\n/, "<br>") + "</#{wrapper_tag}>"
    sanitize_html(html_formatted)
  end

  private

  def sanitize_html(html_formatted)
    html_formatted&.gsub!(/[\r\n]/, ' ')
    with_links = Anchored::Linker.auto_link(html_formatted, target: '_blank', rel: 'noopener')
    tags = ['a', 'abbr', 'acronym', 'address', 'b', 'big', 'blockquote', 'br', 'cite', 'code', 'dd', 'del', 'dfn', 'div', 'dl', 'dt', 'em', 'font', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'i', 'img', 'ins', 'kbd', 'li', 'ol', 'p', 'pre', 'samp', 'small', 'span', 'sub', 'sup', 'table', 'td', 'th', 'tr', 'tt', 'u', 'ul', 'var', 'strong']
    atts = ['target', 'rel', 'href', 'class', 'src', 'alt', 'width', 'height', 'size', 'face', 'color']
    sanitize(with_links, tags: tags, attributes: atts)
  end
end
