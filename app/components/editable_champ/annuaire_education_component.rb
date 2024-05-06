class EditableChamp::AnnuaireEducationComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-select'
  end

  def react_props
    react_input_opts(id: @champ.input_id,
      class: "fr-mt-1w",
      name: @form.field_name(:external_id),
      selected_key: @champ.external_id,
      items: @champ.selected_items,
      loader: data_sources_data_source_education_path,
      minimum_input_length: 3)
  end
end
