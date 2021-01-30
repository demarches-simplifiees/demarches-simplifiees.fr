module ChampHelper
  def has_label?(champ)
    types_without_label = [TypeDeChamp.type_champs.fetch(:header_section), TypeDeChamp.type_champs.fetch(:explication)]
    !types_without_label.include?(champ.type_champ)
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
    sanitized_text.gsub!(/ (\S{15})/, ' \1') if sanitized_text.present? # unbreakable space breaks layout
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
        concat tag.sup("2")
      end
    when GeoArea.sources.fetch(:selection_utilisateur)
      if geo_area.polygon?
        if geo_area.area.present?
          capture do
            concat "Une aire de surface #{geo_area.area} m"
            concat tag.sup("2")
          end
        else
          "Une aire de surface inconnue"
        end
      elsif geo_area.line?
        if geo_area.length.present?
          "Une ligne longue de #{geo_area.length} m"
        else
          "Une ligne de longueur inconnue"
        end
      elsif geo_area.point?
        "Un point situé à #{geo_area.location}"
      end
    end
  end

  def datetime_start_year(date)
    if date == nil || date.year == 0 || date.year >= Date.today.year - 1
      Date.today.year - 1
    else
      date.year
    end
  end
end
