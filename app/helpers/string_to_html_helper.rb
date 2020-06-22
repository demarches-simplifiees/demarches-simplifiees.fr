module StringToHtmlHelper
  def string_to_html(str, wrapper_tag = 'p')
    html_formatted = simple_format(str, {}, { wrapper_tag: wrapper_tag })
    with_links = Anchored::Linker.auto_link(html_formatted, target: '_blank', rel: 'noopener')
    sanitize(with_links, attributes: ['target', 'rel', 'href'])
  end
end
