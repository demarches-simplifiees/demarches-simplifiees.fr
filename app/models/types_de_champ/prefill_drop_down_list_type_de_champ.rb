# frozen_string_literal: true

class TypesDeChamp::PrefillDropDownListTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  def all_possible_values
    if drop_down_other?
      drop_down_list_enabled_non_empty_options.insert(
        0,
        I18n.t("views.prefill_descriptions.edit.possible_values.drop_down_list_other_html")
      )
    else
      drop_down_list_enabled_non_empty_options
    end
  end

  def example_value
    all_possible_values.first
  end
end
