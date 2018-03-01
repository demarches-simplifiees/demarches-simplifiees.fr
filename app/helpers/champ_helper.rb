module ChampHelper
  def is_not_header_nor_explication?(champ)
    !['header_section', 'explication'].include?(champ.type_champ)
  end

  def html_formatted_description(description)
    html_formatted = simple_format(description)
    with_links = html_formatted.gsub(URI.regexp, '<a target="_blank" href="\0">\0</a>')
    sanitize(with_links, attributes: %w(href target))
  end
end
