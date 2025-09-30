# frozen_string_literal: true

class EditableChamp::AddressComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_input_classname
    'fr-select'
  end

  def dsfr_group_classname
    class_names(super, "fr-input-address-ban--disabled" => @champ.not_ban?)
  end

  def react_props
    react_input_opts(id: @champ.focusable_input_id,
      class: 'fr-mt-1w',
      name: @form.field_name(:value),
      placeholder: t('views.components.remote_combobox'),
      selected_key: @champ.selected_key,
      items: @champ.selected_items,
      loader: data_sources_data_source_adresse_path,
      minimum_input_length: 2,
      is_disabled: @champ.not_ban?,
      ariaLabelledbyPrefix: aria_labelledby_prefix,
      labelId: input_label_id(@champ))
  end

  def commune_react_props
    {
      id: @champ.focusable_input_id(:commune_name),
      class: 'fr-mt-1w fr-mb-0',
      name: @form.field_name(:commune_code),
      placeholder: t('views.components.remote_combobox'),
      selected_key: @champ.commune_selected_key,
      items: @champ.commune_selected_items,
      loader: data_sources_data_source_commune_path(with_combined_code: true),
      limit: 20,
      minimum_input_length: 2,
      ariaLabelledbyPrefix: "#{aria_labelledby_prefix} #{champ_fieldset_legend_id(@champ)}",
      labelId: input_label_id(@champ, :commune_name)
    }
  end

  def pays_options
    APIGeoService.countries.map { [_1[:name], _1[:code]] }
  end

  def city_aria_labelledby
    "#{city_aria_labelledby_prefix} #{city_label_id}"
  end

  def aria_labelledby(attribute)
    [aria_labelledby_prefix, attribute == :not_in_ban ? nil : champ_fieldset_legend_id(@champ), input_label_id(@champ, attribute)].compact.join(' ')
  end
end
