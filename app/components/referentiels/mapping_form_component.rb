# frozen_string_literal: true

class Referentiels::MappingFormComponent < ApplicationComponent
  TYPES = {
    String => "Chaine de caractère",
    Float => "Nombre à virgule",
    Integer => "Nombre à Entier",
    TrueClass => "Booléen",
    FalseClass => "Booléen"
  }

  PREFIX = "type_de_champ[referentiel_mapping][]"

  def initialize(procedure:, type_de_champ:, referentiel:)
    @procedure = procedure
    @type_de_champ = type_de_champ
    @referentiel = referentiel
  end

  def last_request_keys
    flatten_hash(@referentiel.last_response)
      .transform_keys { "$.#{_1}" }
  end

  def cast_tag(jsonpath, value)
    attribute = "type"
    current_value = lookup_existing_value(jsonpath, attribute) || value_to_type(value)

    select_tag "#{PREFIX}[#{attribute}]", options_for_select(TYPES.values.uniq, current_value), class: "fr-select"
  end

  def prefill_tag(jsonpath)
    attribute = "prefill"
    current_value = lookup_existing_value(jsonpath, attribute) || false

    check_box_tag "#{PREFIX}[#{attribute}]", "1", current_value, class: "fr-checkbox", data: { "action": "change->referentiel-mapping#onCheckboxChange" }
  end

  def libelle_tag(jsonpath)
    attribute = "libelle"
    current_value = lookup_existing_value(jsonpath, attribute) || jsonpath
    options = { class: 'fr-input', data: { "referentiel-mapping-target": "input" } }
    options[:disabled] = :disabled if lookup_existing_value(jsonpath, "prefill") == "1"

    text_field_tag "#{PREFIX}[#{attribute}]", current_value, options
  end

  private

  def lookup_existing_value(jsonpath, attribute)
    @type_de_champ.referentiel_mapping
      &.find { _1["jsonpath"] == jsonpath }
      &.fetch(attribute) { nil }
  end

  def value_to_type(value)
    TYPES.fetch(value.class) { TYPES[String] }
  end

  def flatten_hash(hash)
    hash.each_with_object({}) do |(k, v), h|
      if v.is_a? Hash
        flatten_hash(v).map do |h_k, h_v|
          h["#{k}.#{h_k}".to_sym] = h_v
        end
      elsif v.is_a? Array
        if v[0].is_a?(Hash)
          flatten_hash(v[0]).each do |hh, _|
            h["#{k}[0].#{hh}"] = v[0][hh]
          end
        else
          h[k] = v[0]
        end
        h
      else
        h[k] = v
      end
    end
  end
end
