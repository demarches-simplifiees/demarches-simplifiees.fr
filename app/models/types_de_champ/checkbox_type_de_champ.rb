class TypesDeChamp::CheckboxTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def filter_to_human(filter_value)
    if filter_value == "true"
      I18n.t('activerecord.attributes.type_de_champ.type_champs.checkbox_true')
    elsif filter_value == "false"
      I18n.t('activerecord.attributes.type_de_champ.type_champs.checkbox_false')
    else
      filter_value
    end
  end
end
