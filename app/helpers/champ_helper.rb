module ChampHelper
  def has_label?(champ)
    types_without_label = [TypeDeChamp.type_champs.fetch(:header_section), TypeDeChamp.type_champs.fetch(:explication)]
    !types_without_label.include?(champ.type_champ)
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

  def auto_attach_url(form, object)
    if object.is_a?(Champ) && object.persisted? && object.public?
      champs_piece_justificative_url(object.id)
    end
  end

  def geo_area_label(geo_area)
    case geo_area.source
    when GeoArea.sources.fetch(:cadastre)
      capture do
        concat "Parcelle n° #{geo_area.numero} - Feuille #{geo_area.code_arr} #{geo_area.section} #{geo_area.feuille} - #{geo_area.surface_parcelle.round} m"
        concat content_tag(:sup, "2")
      end
    when GeoArea.sources.fetch(:quartier_prioritaire)
      "#{geo_area.commune} : #{geo_area.nom}"
    when GeoArea.sources.fetch(:parcelle_agricole)
      "Culture : #{geo_area.culture} - Surface : #{geo_area.surface} ha"
    when GeoArea.sources.fetch(:selection_utilisateur)
      if geo_area.polygon?
        capture do
          concat "Une aire de surface #{geo_area.area} m"
          concat content_tag(:sup, "2")
        end
      elsif geo_area.line?
        "Une ligne longue de #{geo_area.length} m"
      elsif geo_area.point?
        "Un point situé à #{geo_area.location}"
      end
    end
  end
end
