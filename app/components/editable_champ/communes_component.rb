# frozen_string_literal: true

class EditableChamp::CommunesComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  def call
    tag.react_fragment do
      render(ReactComponent.new("ComboBox/RemoteComboBox", **react_props))
    end
  end

  def dsfr_input_classname
    'fr-select'
  end

  def react_props
    react_input_opts(id: @champ.input_id,
      class: 'fr-mt-1w',
      name: @form.field_name(:code),
      selected_key: @champ.selected,
      items: @champ.selected_items,
      loader: data_sources_data_source_commune_path(with_combined_code: true),
      limit: 20,
      minimum_input_length: 2)
  end
end
