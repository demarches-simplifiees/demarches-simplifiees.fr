class TypesDeChamp::YesNoTypeDeChamp < TypesDeChamp::CheckboxTypeDeChamp
  def filter_to_human(filter_value)
    if filter_value == "true"
      "oui"
    elsif filter_value == "false"
      "non"
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
