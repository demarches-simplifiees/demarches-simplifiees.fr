module StringToHtmlHelper
  def string_to_html(str, wrapper_tag = 'p', allow_a: false)
    return nil if str.blank?
    html_formatted = simple_format(str, {}, { wrapper_tag: wrapper_tag })
    with_links = Anchored::Linker.auto_link(html_formatted, target: '_blank', rel: 'noopener')

    tags = if allow_a
      Rails.configuration.action_view.sanitized_allowed_tags + ['a']
    else
      Rails.configuration.action_view.sanitized_allowed_tags
    end

    sanitize(with_links, tags:, attributes: ['target', 'rel', 'href'])
  end
end
