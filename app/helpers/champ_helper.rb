module ChampHelper
  def has_label?(champ)
    types_without_label = [TypeDeChamp.type_champs.fetch(:header_section), TypeDeChamp.type_champs.fetch(:explication)]
    !types_without_label.include?(champ.type_champ)
  end

  def has_html_label?(champ)
    types_with_no_html_label = [TypeDeChamp.type_champs.fetch(:civilite), TypeDeChamp.type_champs.fetch(:yes_no), TypeDeChamp.type_champs.fetch(:datetime), TypeDeChamp.type_champs.fetch(:piece_justificative)
    ]
    types_with_no_html_label.include?(champ.type_champ)
  end

  def geo_data(champ)
    # rubocop:disable Rails/OutputSafety
    raw(champ.to_render_data.to_json)
    # rubocop:enable Rails/OutputSafety
  end

  def champ_carte_params(champ)
    if champ.persisted?
      { champ_id: champ.id }
    else
      { type_de_champ_id: champ.type_de_champ_id }
    end
  end

  def format_text_value(text)
    sanitized_text = sanitize(text)
    auto_linked_text = Anchored::Linker.auto_link(sanitized_text, target: '_blank', rel: 'noopener') do |link_href|
      truncate(link_href, length: 60)
    end
    simple_format(auto_linked_text, {}, sanitize: false)
  end

  def describedby_id(champ)
    if champ.description.present?
      "desc-#{champ.type_de_champ.id}-#{champ.row}"
    end
  end
end
