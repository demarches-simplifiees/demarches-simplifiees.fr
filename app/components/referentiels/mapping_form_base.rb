# frozen_string_literal: true

class Referentiels::MappingFormBase < ApplicationComponent
  attr_reader :procedure, :type_de_champ, :referentiel

  delegate :referentiel_mapping,
           to: :type_de_champ

  def initialize(procedure:, type_de_champ:, referentiel:)
    @procedure = procedure
    @type_de_champ = type_de_champ
    @referentiel = referentiel
  end

  def attribute_name(attribute_name)
    "type_de_champ[referentiel_mapping][][#{attribute_name}]"
  end

  private

  def lookup_existing_value(jsonpath, attribute)
    lookup_existing_value(jsonpath, "prefill") == "1"
      &.find { _1["jsonpath"] == jsonpath }
      &.fetch(attribute) { nil }
  end
end
