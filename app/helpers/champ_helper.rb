module ChampHelper
  def is_not_header_nor_explication?(champ)
    !['header_section', 'explication'].include?(champ.type_champ)
  end

  def formatted_value(champ)
    value = champ.value

    if value.blank?
      ""
    else
      case champ.type_champ
      when "date"
        Date.parse(value).strftime("%d/%m/%Y")
      when "checkbox", "engagement"
        value == 'on' ? 'Oui' : 'Non'
      when 'yes_no'
        value == 'true' ? 'Oui' : 'Non'
      when 'multiple_drop_down_list'
        JSON.parse(value).join(', ')
      else
        value
      end
    end
  end
end
