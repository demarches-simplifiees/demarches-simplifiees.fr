module ChampHelper
  def is_not_header_nor_explication?(champ)
    !['header_section', 'explication'].include?(champ.type_champ)
  end

  def formatted_value(champ)
    if champ.type_champ == "date" && champ.value.present?
      Date.parse(champ.value).strftime("%d/%m/%Y")
    elsif type_champ.in? ["checkbox", "engagement"]
      champ.value == 'on' ? 'Oui' : 'Non'
    elsif type_champ == 'yes_no'
      if champ.value == 'true'
        'Oui'
      elsif champ.value == 'false'
        'Non'
      end
    elsif type_champ == 'multiple_drop_down_list' && champ.value.present?
      JSON.parse(champ.value).join(', ')
    else
      champ.value
    end
  end
end
