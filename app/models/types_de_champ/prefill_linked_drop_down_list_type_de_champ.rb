class TypesDeChamp::PrefillLinkedDropDownListTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def possible_values
    drop_down_list_options.reject(&:empty?)
  end

  def example_value
    return nil if possible_values.empty?
    return possible_values.first if possible_values.one?

    [possible_values.first, possible_values.second]
  end
end
