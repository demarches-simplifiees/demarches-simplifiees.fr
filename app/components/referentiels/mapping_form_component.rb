# frozen_string_literal: true

class Referentiels::MappingFormComponent < Referentiels::MappingFormBase
  TYPES = [:string, :decimal_number, :integer_number, :boolean, :date, :datetime, :array, :geojson].index_by(&:itself).freeze

  attr_reader :referentiel_service

  delegate :test_url, :test_headers, to: :referentiel_service

  def initialize(**args)
    super
    @referentiel_service = ReferentielService.new(referentiel: referentiel)
  end

  def last_request_keys
    JSONPathUtil.hash_to_jsonpath(referentiel.last_response_body)
  end

  def error_title
    "¡Ay, caramba! 💣💥"
  end

  def back_url
    edit_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, referentiel.id)
  end

  def cast_tag(jsonpath, value)
    select_tag(
      attribute_name(jsonpath, "type"),
      options_for_select(self.class::TYPES.values.map { [t("utils.#{it}"), it] }, lookup_existing_value(jsonpath, "type") || value_to_type(value)),
      class: "fr-select"
    )
  end

  def prefill_tag(jsonpath)
    tag.div(class: "fr-checkbox-group") do
      safe_join([
        hidden_field_tag(attribute_name(jsonpath, "prefill"), "0"),
        check_box_tag(attribute_name(jsonpath, "prefill"), "1", lookup_existing_value(jsonpath, "prefill") == "1", class: "fr-checkbox", id: jsonpath.parameterize, data: { "action": "change->referentiel-mapping#onCheckboxChange" }, aria: { labelledby: label_check_prefill(jsonpath) }),
        tag.label(for: jsonpath.parameterize, class: "fr-label", aria: { hidden: true }) { sanitize("&nbsp;") }
      ])
    end
  end

  def enabled_libelle_tag(jsonpath)
    text_field_tag(
      attribute_name(jsonpath, "libelle"),
      lookup_existing_value(jsonpath, "libelle") || jsonpath,
      libelle_field_options(jsonpath)
    )
  end

  def disabled_libelle_tag(jsonpath)
    safe_join([
      tag.p("Libellé du champ du formulaire"),
      tag.p("(à définir à l'étape suivante)", class: 'fr-text--sm fr-text-action-high--blue-france')
    ])
  end

  def label_check_prefill(jsonpath)
    "use-for-prefill-#{jsonpath.parameterize}"
  end

  private

  def disabled?(jsonpath)
    lookup_existing_value(jsonpath, "prefill") == "1"
  end

  def value_to_type(value)
    if ReferentielMappingUtils.geojson_object?(value)
      self.class::TYPES[:geojson]
    elsif value.is_a?(String) && DateDetectionUtils.parsable_iso8601_datetime?(value)
      self.class::TYPES[:datetime]
    elsif value.is_a?(String) && DateDetectionUtils.parsable_iso8601_date?(value)
      self.class::TYPES[:date]
    elsif ReferentielMappingUtils.array_of_supported_simple_types?(value)
      self.class::TYPES[:array]
    elsif value.is_a?(Float)
      self.class::TYPES[:decimal_number]
    elsif value.is_a?(Integer)
      self.class::TYPES[:integer_number]
    elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
      self.class::TYPES[:boolean]
    else
      TYPES.fetch(:string)
    end
  end

  def libelle_field_options(jsonpath)
    {
      class: 'fr-input',
      data: {
        "referentiel-mapping-target": "input",
        'referentiel-mapping-enabled-value': disabled?(jsonpath)
      }
    }
  end
end
