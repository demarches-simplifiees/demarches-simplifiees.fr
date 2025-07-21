# frozen_string_literal: true

class Champs::ReferentielChamp < Champ
  delegate :referentiel,
           :referentiel_mapping_displayable,
           :referentiel_mapping_prefillable_with_stable_id,
           to: :type_de_champ
  before_save :clear_previous_result, if: -> { external_id_changed? }

  validates_with ReferentielChampValidator, if: :validate_champ_value?

  def fetch_external_data
    ReferentielService.new(referentiel:).call(external_id)
  end

  def update_external_data!(data:)
    transaction do
      update!(
        value: external_id,                # now that we have the data, we can set the value
        data:,                             # keep raw API response
        value_json: cast_displayable_values(data.with_indifferent_access), # columnize the data
        fetch_external_data_exceptions: [] # void previous errors
      )
      propagate_prefill(data)
    end
  end

  def uses_external_data?
    true
  end

  def should_ui_auto_refresh?
    true
  end

  def prefillable_stable_ids
    referentiel_mapping_prefillable_with_stable_id
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
    in [:carte, v] if ReferentielMappingUtils.geojson_object?(v)
      flatten_geojson(v)
        .filter { GeojsonService.valid_wgs84_coordinates?(it) }
        .map { GeoArea.build(geometry: it['geometry'], properties: it['properties'], source: 'selection_utilisateur') }
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
    value = call_caster(type_de_champ.type_champ, value, type_de_champ)
    case type_de_champ.type_champ.to_sym
    when :carte
      { geo_areas: value }.merge(prefilled: true)
    else
      { value: }.merge(prefilled: true)
    end
  end

  def cast_displayable_values(data)
    referentiel_mapping_displayable.reduce({}) do |accu, (jsonpath, mapping)|
      casted_value = call_caster(mapping[:type], JsonPath.on(data, jsonpath).first)
      accu[jsonpath] = casted_value if !casted_value.nil?
      accu
    end
  end

  def propagate_prefill(data)
    # the champ is on the right stream, but the dossier might not be. We set dossier stream from the champ
    dossier.with_champ_stream(self)

    types_de_champ_by_stable_id = dossier.revision.types_de_champ.index_by(&:stable_id)
    referentiel_mapping_prefillable_with_stable_id
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
      json_array = JsonPath.on(data.with_indifferent_access, array_key).first || []
      next unless json_array.is_a?(Array)
      json_array.each do |json_value|
        next if json_value.blank?
        row_id = dossier.repetition_add_row(repetition_type_de_champ, updated_by: :api)
        array_mappings.each do |jsonpath, type_de_champ|
          raw_value = JsonPath.on(json_value, JSONPathUtil.extract_key_after_array(jsonpath)).first
          update_prefillable_champ(type_de_champ:, raw_value:, row_id:)
        end
      end
    end
  end

  def group_mappings_by_json_array(mappings)
    mappings.group_by { |jsonpath, _| JSONPathUtil.extract_array_name(jsonpath) }
  end

  def update_simple_prefillable_champs(data, mappings)
    mappings.each do |jsonpath, type_de_champ|
      raw_value = JsonPath.on(data.with_indifferent_access, jsonpath).first
      update_prefillable_champ(type_de_champ:, raw_value:)
    end
  end

  def update_prefillable_champ(type_de_champ:, raw_value:, row_id: nil)
    prefill_champ = dossier.champ_for_update(type_de_champ, row_id:, updated_by: :api)
    prefill_champ.update(cast_value_for_type_de_champ(raw_value, type_de_champ))
  end

  def flatten_geojson(geojson)
    case geojson["type"] || geojson[:type]
    when "FeatureCollection"
      geojson["features"]
    when "Feature"
      [geojson]
    else
      [{ "geometry" => geojson, "properties" => {} }]
    end
  end
end
