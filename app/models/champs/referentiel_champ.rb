# frozen_string_literal: true

class Champs::ReferentielChamp < Champ
  delegate :referentiel, to: :type_de_champ

  before_save :clear_previous_result, if: -> { external_id_changed? }

  validates_with ReferentielChampValidator, if: :validate_champ_value?

  def fetch_external_data
    ReferentielService.new(referentiel:).call(external_id)
  end

  def update_with_external_data!(data:)
    transaction do
      update!(
        value: external_id,                # now that we have the data, we can set the value
        data:,                             # keep raw API response
        value_json: todo_map_stuff(data:), # columnize the data
        fetch_external_data_exceptions: [] # void previous errors
      )
      propagate_prefill(data)
    end
  end

  def todo_map_stuff(data:)
    data
  end

  def fetch_external_data?
    true
  end

  def poll_external_data?
    true
  end

  def prefillable_stable_ids
    type_de_champ
      .referentiel_mapping_prefillable_with_stable_id
      .map { |_jsonpath, mapping| mapping[:prefill_stable_id].to_i }
  end

  def prefillable_champs
    elligible_stable_ids = prefillable_stable_ids
    if public?
      dossier.project_champs_public
    else
      dossier.project_champs_private
    end.filter do |champ|
      if champ.repetition?
        dossier.revision.children_of(champ.type_de_champ).any? { _1.stable_id.in?(elligible_stable_ids) }
      else
        champ.stable_id.in?(elligible_stable_ids)
      end
    end
  end

  private

  def clear_previous_result
    self.value = nil
    self.data = nil
    self.value_json = nil
    self.fetch_external_data_exceptions = []
  end

  def cast_value_for_type_de_champ(value, type_de_champ)
    result = case [type_de_champ.type_champ, value]
    in ['integer_number', v] if v.present?
      { value: v.to_i }
    in ['decimal_number', v] if v.present?
      { value: v.to_f }
    in ['checkbox' | 'yes_no', v]
      bool = ActiveModel::Type::Boolean.new.cast(v)
      { value: (bool.nil? ? nil : (bool ? Champs::BooleanChamp::TRUE_VALUE : Champs::BooleanChamp::FALSE_VALUE)) }
    in ['datetime', v]
      { value: DateDetectionUtils.convert_to_iso8601_datetime(v) }
    in ['date', v]
      { value: DateDetectionUtils.convert_to_iso8601_date(v) }
    in ['drop_down_list', Array => arr] if ReferentielMappingUtils.array_of_supported_simple_types?(arr)
      { value: arr.first.to_s }
    in ['drop_down_list', v] if type_de_champ.value_is_in_options?(v) || type_de_champ.drop_down_other?
      { value: v.to_s }
    in ['multiple_drop_down_list', Array => arr] if ReferentielMappingUtils.array_of_supported_simple_types?(arr)
      { value: arr.to_json }
    in ['text'| 'textarea' |'engagement_juridique'| 'dossier_link' | 'email'| 'phone'| 'iban'| 'siret' | 'formatted', v]
      { value: value.to_s }
    else # nothing found, maybe an invalid something
      {}
    end
    (result || {}).merge(prefilled: true)
  end

  def propagate_prefill(data)
    # the champ is on the right stream, but the dossier might not be. We set dossier stream from the champ
    dossier.with_champ_stream(self)

    types_de_champ_by_stable_id = dossier.revision.types_de_champ.index_by(&:stable_id)
    type_de_champ
      .referentiel_mapping_prefillable_with_stable_id
      .transform_values do |mapping|
        types_de_champ_by_stable_id.fetch(mapping[:prefill_stable_id].to_i)
      end.group_by do |_, type_de_champ|
        dossier.revision.parent_of(type_de_champ)
      end.each do |repetition_type_de_champ, mappings|
        if repetition_type_de_champ.present?
          update_repetition_prefillable_champs(data, repetition_type_de_champ, mappings)
        else
          update_simple_prefillable_champs(data, mappings)
        end
      end
  end

  def update_repetition_prefillable_champs(data, repetition_type_de_champ, mappings)
    group_mappings_by_json_array(mappings).each do |array_key, array_mappings|
      json_array = JSONPath.get_array(data.with_indifferent_access, array_key) || []
      next unless json_array.is_a?(Array)
      json_array.each do |json_value|
        next if json_value.blank?
        row_id = dossier.repetition_add_row(repetition_type_de_champ, updated_by: :api)
        array_mappings.each do |jsonpath, type_de_champ|
          raw_value = JSONPath.value(json_value, JSONPath.extract_key_after_array(jsonpath))
          update_prefillable_champ(type_de_champ:, raw_value:, row_id:)
        end
      end
    end
  end

  def group_mappings_by_json_array(mappings)
    mappings.group_by { |jsonpath, _| JSONPath.extract_array_name(jsonpath) }
  end

  def update_simple_prefillable_champs(data, mappings)
    mappings.each do |jsonpath, type_de_champ|
      raw_value = JSONPath.value(data.with_indifferent_access, jsonpath)
      update_prefillable_champ(type_de_champ:, raw_value:)
    end
  end

  def update_prefillable_champ(type_de_champ:, raw_value:, row_id: nil)
    prefill_champ = dossier.champ_for_update(type_de_champ, row_id:, updated_by: :api)
    prefill_champ.update(cast_value_for_type_de_champ(raw_value, type_de_champ))
  end
end
