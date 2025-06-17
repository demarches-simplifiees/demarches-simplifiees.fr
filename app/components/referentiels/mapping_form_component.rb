# frozen_string_literal: true

class Referentiels::MappingFormComponent < Referentiels::MappingFormBase
  TYPES = {
    String => "Chaine de caractère",
    Float => "Nombre à virgule",
    Integer => "Nombre Entier",
    TrueClass => "Booléen",
    FalseClass => "Booléen",
    # detection
    "Date" => "Date",
    "DateTime" => "Date et heure",
    "Liste à choix multiples" => "Liste à choix multiples"
  }.freeze

  def last_request_keys
    JSONPath.hash_to_jsonpath(referentiel.last_response_body)
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
      options_for_select(self.class::TYPES.values.uniq, lookup_existing_value(jsonpath, "type") || value_to_type(value)),
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
    if value.is_a?(String) && DateDetectionUtils.parsable_iso8601_datetime?(value)
      self.class::TYPES["DateTime"]
    elsif value.is_a?(String) && DateDetectionUtils.parsable_iso8601_date?(value)
      self.class::TYPES["Date"]
    elsif ReferentielMappingUtils.array_of_supported_simple_types?(value)
      self.class::TYPES["Liste à choix multiples"]
    else
      TYPES.fetch(value.class) { TYPES[String] }
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
