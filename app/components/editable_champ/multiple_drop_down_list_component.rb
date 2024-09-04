# frozen_string_literal: true

class EditableChamp::MultipleDropDownListComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  def dsfr_input_classname
    'fr-select'
  end

  def dsfr_champ_container
    @champ.render_as_checkboxes? ? :fieldset : :div
  end

  def react_props
    react_input_opts(id: @champ.input_id,
      class: 'fr-mt-1w',
      name: @form.field_name(:value, multiple: true),
      selected_keys: @champ.selected_options,
      items: @champ.enabled_non_empty_options,
      'aria-label': @champ.libelle,
      'aria-describedby': @champ.describedby_id,
      'aria-labelledby': @champ.labelledby_id)
  end
end
