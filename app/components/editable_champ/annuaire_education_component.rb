# frozen_string_literal: true

class EditableChamp::AnnuaireEducationComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-select'
  end

  def react_props
    react_input_opts(id: @champ.focusable_input_id,
      class: "fr-mt-1w",
      name: @form.field_name(:external_id),
      selected_key: @champ.external_id,
      items: @champ.selected_items,
      loader: 'https://data.education.gouv.fr/api/records/1.0/search?dataset=fr-en-annuaire-education&rows=5',
      coerce: 'AnnuaireEducation',
      debounce: 500,
      minimum_input_length: 5,
      ariaLabelledbyPrefix: aria_labelledby_prefix,
      labelId: @champ.label_id)
  end
end
