# frozen_string_literal: true

class EditableChamp::DropDownListComponent < EditableChamp::EditableChampBaseComponent
  def render?
    @champ.drop_down_options.any?
  end

  def select_class_names
    class_names('width-100': contains_long_option?, 'fr-select': true)
  end

  def dsfr_input_classname
    'fr-select'
  end

  def dsfr_champ_container
    @champ.render_as_radios? ? :fieldset : :div
  end

  def other_element_class_names
    class_names("fr-fieldset__element" => dsfr_champ_container == :fieldset)
  end

  def contains_long_option?
    max_length = 100
    @champ.drop_down_options.any? { _1.size > max_length }
  end

  def react_props
    react_input_opts(
      id: @champ.input_id,
      class: 'fr-mt-1w',
      name: @form.field_name(:value),
      selected_key: @champ.selected,
      items: @champ.drop_down_options_with_other.map { _1.is_a?(Array) ? _1 : [_1, _1] },
      empty_filter_key: @champ.drop_down_other? ? Champs::DropDownListChamp::OTHER : nil
    )
  end
end
