class TypesDeChamp::YesNoTypeDeChamp < TypesDeChamp::CheckboxTypeDeChamp
  def filter_to_human(filter_value)
    if filter_value == "true"
      I18n.t('activerecord.attributes.type_de_champ.type_champs.yes_no_true')
    elsif filter_value == "false"
      I18n.t('activerecord.attributes.type_de_champ.type_champs.yes_no_false')
    else
      filter_value
    end
  end

  def human_to_filter(human_value)
    human_value.downcase!
    if human_value == "oui"
      "true"
    elsif human_value == "non"
      "false"
    else
      human_value
    end
  end
end
