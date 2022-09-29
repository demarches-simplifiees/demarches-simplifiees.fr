module StringToHtmlHelper
  def string_to_html(str, wrapper_tag = 'p')
    return nil if str.blank?
    html_formatted = "<#{wrapper_tag}>" + str.to_s.gsub(/(?<![>\r])\r?\n/, "<br>") + "</#{wrapper_tag}>"
    sanitize_html(html_formatted)
  end

  private

  def sanitize_html(html_formatted)
    html_formatted&.gsub!(/[\r\n]/, ' ')
    with_links = Anchored::Linker.auto_link(html_formatted, target: '_blank', rel: 'noopener')
    sanitize(with_links)
  end
end
