module StringToHtmlHelper
  def string_to_html(str, wrapper_tag = 'p', allow_a: nil)
    return nil if str.blank?
    html_formatted = "<#{wrapper_tag}>" + str.to_s.gsub(/(?<![>\r])\r?\n/, "<br>") + "</#{wrapper_tag}>"
    sanitize_html(html_formatted, allow_a:)
  end

  private

  def sanitize_html(html_formatted, allow_a: nil)
    html_formatted&.gsub!(/[\r\n]/, ' ')
    with_links = Anchored::Linker.auto_link(html_formatted, target: '_blank', rel: 'noopener')
    sanitized_allowed_tags = Rails.configuration.action_view.sanitized_allowed_tags
    tags = if allow_a.nil?
      sanitized_allowed_tags
    elsif allow_a
      sanitized_allowed_tags + ['a']
    else
      sanitized_allowed_tags - ['a']
    end
    sanitize(with_links, tags:)
  end
end
