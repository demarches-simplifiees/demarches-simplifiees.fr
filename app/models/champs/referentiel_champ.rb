# frozen_string_literal: true

class Champs::ReferentielChamp < Champ
  delegate :referentiel,
           :referentiel_mapping_displayable_for_instructeur,
           :referentiel_mapping_displayable_for_usager,
           :referentiel_mapping_prefillable_with_stable_id,
           to: :type_de_champ
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
        value_json: map_displayable(data:), # columnize the data
        fetch_external_data_exceptions: [] # void previous errors
      )
      propagate_prefill(data)
    end
  end

  def map_displayable(data:)
    {
      display_usager: cast_displayable_values(referentiel_mapping_displayable_for_usager, data.with_indifferent_access),
      display_instructeur: cast_displayable_values(referentiel_mapping_displayable_for_instructeur, data.with_indifferent_access)
    }
  end

  def fetch_external_data?
    true
  end

  def poll_external_data?
    true
  end

  def prefillable_stable_ids
    referentiel_mapping_prefillable_with_stable_id.map { |_jsonpath, mapping| mapping[:prefill_stable_id] }
  end

  def prefillable_champs
    elligible_stable_ids = prefillable_stable_ids.map(&:to_s)
    dossier.project_champs_public.filter do |champ|
      if champ.repetition?
        champ.rows.flatten.any? { it.type_de_champ.stable_id.to_s.in?(elligible_stable_ids) }
      else
        champ.public_id.to_s.in?(elligible_stable_ids)
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

  def call_caster(mapping_or_type_champ, value, type_de_champ = nil)
    case [mapping_or_type_champ&.to_sym, value]
    in [:integer_number, v] if v.present?
      v.to_i
    in [:decimal_number, v] if v.present?
      v.to_f
    in [:datetime, v]
      DateDetectionUtils.convert_to_iso8601_datetime(v)
    in [:date, v]
      DateDetectionUtils.convert_to_iso8601_date(v)
    # cases of type from tdc, used to store in a champ
    in [:drop_down_list, Array => arr] if ReferentielMappingUtils.array_of_supported_simple_types?(arr)
      arr.first.to_s
    in [:drop_down_list, v] if type_de_champ&.value_is_in_options?(v) || type_de_champ&.drop_down_other?
      v.to_s
    in [:multiple_drop_down_list, Array => arr] if ReferentielMappingUtils.array_of_supported_simple_types?(arr)
      arr.compact.to_json
    in [:checkbox | :yes_no, v]
      bool = ActiveModel::Type::Boolean.new.cast(v)
      bool.nil? ? nil : (bool ? Champs::BooleanChamp::TRUE_VALUE : Champs::BooleanChamp::FALSE_VALUE)
    in [:text | :textarea | :engagement_juridique| :dossier_link | :email| :phone| :iban| :siret | :formatted, v]
      v.to_s
    # case of type from mapping, used to store for display
    in [:boolean, v]
      ActiveModel::Type::Boolean.new.cast(v)
    in [:array, Array => arr] if ReferentielMappingUtils.array_of_supported_simple_types?(arr)
      Array(arr)
    in [:string, v]
      v.to_s
    else
      nil
    end
  end

  def cast_value_for_type_de_champ(value, type_de_champ)
    { value: call_caster(type_de_champ.type_champ, value, type_de_champ) }.merge(prefilled: true)
  end

  def cast_displayable_values(mappings, data)
    mappings.reduce({}) do |accu, (jsonpath, mapping)|
      casted_value = call_caster(mapping[:type], JSONPath.value(data, jsonpath))
      accu[jsonpath] = casted_value if casted_value
      accu
    end
  end

  def propagate_prefill(data)
    referentiel_mapping_prefillable_with_stable_id
      .group_by { |_jsonpath, mapping| dossier.revision.parent_of(dossier.find_type_de_champ_by_stable_id(mapping[:prefill_stable_id])) }
      .each do |repetition, mappings|
        if repetition.present?
          update_repetition_prefillable_champs(data, repetition, mappings)
        else
          update_simple_prefillable_champs(data, mappings)
        end
      end
  end

  def update_repetition_prefillable_champs(data, repetition, mappings)
    group_mappings_by_json_array(mappings).each do |array_key, array_mappings|
      json_array = JSONPath.get_array(data.with_indifferent_access, array_key) || []
      next unless json_array.is_a?(Array)
      json_array.each do |element|
        next if element.blank?
        row_id = dossier.repetition_add_row(repetition, updated_by: :api)
        array_mappings.each do |jsonpath, mapping|
          value = extract_value_for_mapping(element, jsonpath)
          update_prefillable_champ(
            stable_id: mapping[:prefill_stable_id],
            raw_value: value,
            row_id: row_id
          )
        end
      end
    end
  end

  def group_mappings_by_json_array(mappings)
    mappings.group_by { |jsonpath, _| JSONPath.extract_array_name((jsonpath)) }
  end

  def extract_value_for_mapping(element, jsonpath)
    after_bracket = JSONPath.extract_key_after_array((jsonpath))
    JSONPath.value(element, after_bracket)
  end

  def update_simple_prefillable_champs(data, mappings)
    mappings.each do |jsonpath, mapping|
      update_prefillable_champ(
        stable_id: mapping[:prefill_stable_id],
        raw_value: JSONPath.value(data.with_indifferent_access, (jsonpath))
      )
    end
  end

  def update_prefillable_champ(stable_id:, raw_value:, row_id: nil)
    prefill_champ = find_prefillable_champ(stable_id:, row_id:)
    prefill_champ.update(cast_value_for_type_de_champ(raw_value, prefill_champ.type_de_champ)) if prefill_champ.present?
  end

  def find_prefillable_champ(stable_id:, row_id: nil)
    prefillable_type_de_champ = dossier.find_type_de_champ_by_stable_id(stable_id)
    dossier.champ_for_update(prefillable_type_de_champ, row_id:, updated_by: :api)
  end
end
