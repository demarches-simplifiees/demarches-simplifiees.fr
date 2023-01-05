class TypesDeChamp::PrefillDropDownListTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  # TODO: SEB manage drop down list with "other"
  def possible_values
    drop_down_list_enabled_non_empty_options
  end

  def example_value
    possible_values.first
  end
end
