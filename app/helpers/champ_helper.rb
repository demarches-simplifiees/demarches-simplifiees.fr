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

  def formatted_value(champ)
    value = champ.value
    type = champ.type_champ

    if type == TypeDeChamp.type_champs.fetch(:date)
      champ.to_s
    elsif type.in? [TypeDeChamp.type_champs.fetch(:checkbox), TypeDeChamp.type_champs.fetch(:engagement)]
      champ.to_s
    elsif type == TypeDeChamp.type_champs.fetch(:yes_no)
      champ.to_s
    elsif type == TypeDeChamp.type_champs.fetch(:multiple_drop_down_list)
      champ.to_s
    else
      value
    end
  end
end
