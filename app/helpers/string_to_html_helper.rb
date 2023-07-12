module StringToHtmlHelper
  def string_to_html(str, wrapper_tag = 'p', allow_a: false)
    return nil if str.blank?
    html_formatted = "<#{wrapper_tag}>" + str.to_s.gsub(/(?<![>\r])\r?\n/, "<br>") + "</#{wrapper_tag}>"
    sanitize_html(html_formatted)
  end

  private

  def sanitize_html(html_formatted, allow_a: false)
    html_formatted&.gsub!(/[\r\n]/, ' ')
    with_links = Anchored::Linker.auto_link(html_formatted, target: '_blank', rel: 'noopener')
    tags = if allow_a
      Rails.configuration.action_view.sanitized_allowed_tags + ['a']
    else
      Rails.configuration.action_view.sanitized_allowed_tags
    end
    sanitize(with_links, tags:)
  end
end
