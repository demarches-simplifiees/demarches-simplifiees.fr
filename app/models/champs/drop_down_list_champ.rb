class Champs::DropDownListChamp < Champ
  THRESHOLD_NB_OPTIONS_AS_RADIO = 5

  def render_as_radios?
    drop_down_list.enabled_non_empty_options.size <= THRESHOLD_NB_OPTIONS_AS_RADIO
  end
end
