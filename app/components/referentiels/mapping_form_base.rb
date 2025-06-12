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

  def attribute_name(jsonpath, attribute_name)
    "type_de_champ[referentiel_mapping][#{jsonpath}][#{attribute_name}]"
  end

  private

  def lookup_existing_value(jsonpath, attribute)
    referentiel_mapping&.dig(jsonpath, attribute)
  end
end
