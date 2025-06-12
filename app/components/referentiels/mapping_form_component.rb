# frozen_string_literal: true

class Referentiels::MappingFormComponent < Referentiels::MappingFormBase
  TYPES = {
    String => "Chaine de caractère",
    Float => "Nombre à virgule",
    Integer => "Nombre Entier",
    TrueClass => "Booléen",
    FalseClass => "Booléen"
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
    attribute = "type"
    current_value = lookup_existing_value(jsonpath, attribute) || value_to_type(value)

    select_tag "#{PREFIX}[#{attribute}]", options_for_select(TYPES.values.uniq, current_value), class: "fr-select"
  end

  def prefill_tag(jsonpath)
    attribute = "prefill"
    current_value = lookup_existing_value(jsonpath, attribute) || false
    tag.div(class: "fr-checkbox-group") do
      safe_join([
        check_box_tag("#{PREFIX}[#{attribute}]", "1", current_value, class: "fr-checkbox", id: jsonpath.parameterize, data: { "action": "change->referentiel-mapping#onCheckboxChange" }, aria: { labelledby: label_check_prefill(jsonpath) }),
        tag.label(for: jsonpath.parameterize, class: "fr-label", aria: { hidden: true }) { sanitize("&nbsp;") }
      ])
    end
  end

  def enabled_libelle_tag(jsonpath)
    attribute = "libelle"
    current_value = lookup_existing_value(jsonpath, attribute) || jsonpath
    options = { class: 'fr-input', data: { "referentiel-mapping-target": "input", 'referentiel-mapping-enabled-value': disabled?(jsonpath) } }
    text_field_tag "#{PREFIX}[#{attribute}]", current_value, options
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
    TYPES.fetch(value.class) { TYPES[String] }
  end
end
