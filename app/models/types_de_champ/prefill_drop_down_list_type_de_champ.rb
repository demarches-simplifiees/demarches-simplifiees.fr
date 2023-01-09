class TypesDeChamp::PrefillDropDownListTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def possible_values
    possible_values = drop_down_list_enabled_non_empty_options
    if drop_down_other?
      possible_values.insert(
        0,
        I18n.t("views.prefill_descriptions.edit.possible_values.drop_down_list_other")
      )
    end
    possible_values
  end

  def example_value
    possible_values.first
  end
end
