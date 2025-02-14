# frozen_string_literal: true

class Referentiels::MappingFormComponent < ApplicationComponent
  TYPES = {
    String => "Chaine de caractère",
    Float => "Nombre à virgule",
    Integer => "Nombre Entier",
    TrueClass => "Booléen",
    FalseClass => "Booléen"
  }

  PREFIX = "type_de_champ[referentiel_mapping][]"

  attr_reader :procedure, :type_de_champ, :referentiel

  def initialize(procedure:, type_de_champ:, referentiel:)
    @procedure = procedure
    @type_de_champ = type_de_champ
    @referentiel = referentiel
  end

  def last_request_keys
    hash_to_jsonpath(referentiel.last_response_body)
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
        check_box_tag("#{PREFIX}[#{attribute}]", "1", current_value, class: "fr-checkbox", id: jsonpath.parameterize, data: { "action": "change->referentiel-mapping#onCheckboxChange" }),
        tag.label(for: jsonpath.parameterize, class: "fr-label") { sanitize("&nbsp;") }
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

  private

  def disabled?(jsonpath)
    lookup_existing_value(jsonpath, "prefill") == "1"
  end

  def lookup_existing_value(jsonpath, attribute)
    type_de_champ.referentiel_mapping
      &.find { _1["jsonpath"] == jsonpath }
      &.fetch(attribute) { nil }
  end

  def value_to_type(value)
    TYPES.fetch(value.class) { TYPES[String] }
  end

  def hash_to_jsonpath(hash, parent_path = '$')
    hash.each_with_object({}) do |(key, value), result|
      current_path = "#{parent_path}.#{key}"

      if value.is_a?(Hash)
        result.merge!(hash_to_jsonpath(value, current_path))
      elsif value.is_a?(Array) && value[0].is_a?(Hash)

        result.merge!(hash_to_jsonpath(value[0], "#{current_path}[0]"))
      else
        result[current_path] = value
      end
    end
  end
end
