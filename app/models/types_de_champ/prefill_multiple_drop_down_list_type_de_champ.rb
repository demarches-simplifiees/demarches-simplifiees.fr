class TypesDeChamp::PrefillMultipleDropDownListTypeDeChamp < TypesDeChamp::PrefillDropDownListTypeDeChamp
  def example_value
    return nil if possible_values.empty?
    return possible_values.first if possible_values.one?

    [possible_values.first, possible_values.second]
  end
end
