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

  def select_aria_describedby
    describedby = []
    describedby << @champ.describedby_id if @champ.description.present?
    describedby << @champ.error_id if errors_on_attribute?
    describedby.present? ? describedby.join(' ') : nil
  end

  def react_props
    react_input_opts(
      id: @champ.input_id,
      class: 'fr-mt-1w',
      name: @form.field_name(:value),
      selected_key: @champ.selected,
      items:,
      empty_filter_key: @champ.drop_down_other? ? Champs::DropDownListChamp::OTHER : nil,
      max_items_alert: t('.exceed_options_threshold_alert')
    )
  end

  def items
    @champ.options_for_select_with_other
  end
end
