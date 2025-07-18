# frozen_string_literal: true

class Referentiels::PrefillAndDisplayComponent < ViewComponent::Base
  attr_reader :procedure, :type_de_champ, :referentiel

  def initialize(procedure:, type_de_champ:, referentiel:)
    @procedure = procedure
    @type_de_champ = type_de_champ
    @referentiel = referentiel
  end
end
