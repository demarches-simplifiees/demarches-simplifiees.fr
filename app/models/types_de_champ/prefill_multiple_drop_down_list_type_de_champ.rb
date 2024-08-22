# frozen_string_literal: true

class TypesDeChamp::PrefillMultipleDropDownListTypeDeChamp < TypesDeChamp::PrefillDropDownListTypeDeChamp
  def example_value
    return nil if all_possible_values.empty?
    return all_possible_values.first if all_possible_values.one?

    [all_possible_values.first, all_possible_values.second]
  end
end
