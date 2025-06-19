# frozen_string_literal: true

class Referentiels::MappingFormBase < ApplicationComponent
  attr_reader :procedure, :type_de_champ, :referentiel

  delegate :referentiel_mapping,
           to: :type_de_champ

  # posting real json path to controller is interpreted as nested hashes
  # ie : repetition[0].field_name becomes
  # {
  #   "repetition": [
  #     { "field_name": "value" }
  #   ]
  # }
  # In case of deeply nested structure it becomes a pain to handle with StrongParameters
  # So we rewrite the jsonpath to avoid this
  def self.jsonpath_to_simili(jsonpath)
    jsonpath.tr('[', '{').tr(']', '}')
  end

  def self.simili_to_jsonpath(jsonpath)
    jsonpath.tr('{', '[').tr('}', ']')
  end

  def initialize(procedure:, type_de_champ:, referentiel:)
    @procedure = procedure
    @type_de_champ = type_de_champ
    @referentiel = referentiel
  end

  def attribute_name(jsonpath, attribute_name)
    "type_de_champ[referentiel_mapping][#{jsonpath}][#{JSONPath.jsonpath_to_simili(attribute_name)}]"
  end

  def bordered_container_class_names
    "border-background-contrast-grey fr-p-4w"
  end

  private

  def lookup_existing_value(jsonpath, attribute)
    referentiel_mapping&.dig(jsonpath, attribute)
  end
end
