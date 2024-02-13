class EditableChamp::DropDownListComponent < EditableChamp::EditableChampBaseComponent
  def select_class_names
    class_names('width-100': contains_long_option?, 'fr-select': true)
  end

  def dsfr_input_classname
    'fr-select'
  end

  def dsfr_champ_container
    @champ.render_as_radios? ? :fieldset : :div
  end

  def contains_long_option?
    max_length = 100
    @champ.enabled_non_empty_options.any? { _1.size > max_length }
  end
end
