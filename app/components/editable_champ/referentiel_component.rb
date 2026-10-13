# frozen_string_literal: true

class EditableChamp::ReferentielComponent < EditableChamp::EditableChampBaseComponent
  delegate :type_de_champ, to: :@champ
  delegate :referentiel, to: :type_de_champ
  delegate :exact_match?, to: :referentiel, allow_nil: true

  def locked? = @champ.locked_prefill?

  def locked_message_id = "#{@champ.html_id}-locked"

  def described_by
    [@champ.describedby_id, @champ.error_id(:value), (locked_message_id if locked?)].compact.join(' ')
  end

  def dsfr_input_classname
    exact_match? ? 'fr-input' : nil
  end

  def react_autocomplete_props
    react_input_opts(id: @champ.focusable_input_id,
      class: 'fr-mt-1w',
      name: @form.field_name(:value),
      placeholder: t('views.components.remote_combobox'),
      selected_key: @champ.selected_key,
      items: @champ.selected_items,
      limit: ReferentielAutocompleteRenderService::MAX_RENDERED_OBJECTS,
      loader: data_sources_data_source_referentiel_path(referentiel_id: referentiel.id, dossier_id: @champ.dossier_id, row_id: @champ.row_id),
      minimum_input_length: DataSources::ReferentielController::MIN_QUERY_LENGTH,
      use_post: true,
      is_disabled: locked?,
      ariaLabelledbyPrefix: aria_labelledby_prefix,
      labelId: input_label_id(@champ),
      inputId: @champ.focusable_input_id)
  end
end
