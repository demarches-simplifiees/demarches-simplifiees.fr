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
    simple_format(auto_linked_text, {}, sanitize: false)
  end

  def auto_attach_url(object)
    if object.is_a?(Champ)
      champs_piece_justificative_url(object.id)
    end
  end

  def autosave_available?(champ)
    # FIXME: enable autosave on champs private? once we figured out how to batch audit events
    champ.dossier.brouillon? && !champ.repetition?
  end

  def editable_champ_controller(champ)
    if !champ.repetition? && !champ.non_fillable?
      # This is an editable champ. Lets find what controllers it might need.
      controllers = []

      # This is a public champ – it can have an autosave controller.
      if champ.public?
        # This is a champ on dossier in draft state. Activate autosave.
        if champ.dossier.brouillon?
          controllers << 'autosave'
        # This is a champ on a dossier in en_construction state. Enable conditions checker.
        elsif champ.public? && champ.dossier.en_construction?
          controllers << 'check-conditions'
        end
      end

      # This is a dropdown champ. Activate special behaviours it might have.
      if champ.simple_drop_down_list? || champ.linked_drop_down_list?
        controllers << 'champ-dropdown'
      end

      if controllers.present?
        { controller: controllers.join(' ') }
      end
    end
  end

  def geo_area_label(geo_area)
    case geo_area.source
    when GeoArea.sources.fetch(:cadastre)
      safe_join ["Parcelle n° #{geo_area.numero} - Feuille #{geo_area.prefixe} #{geo_area.section} - #{geo_area.surface.round} m", tag.sup("2")]
    when GeoArea.sources.fetch(:selection_utilisateur)
      if geo_area.polygon?
        if geo_area.area.present?
          safe_join ["Une aire de surface #{geo_area.area} m", tag.sup("2")]
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
