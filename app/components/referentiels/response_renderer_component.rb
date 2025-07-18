# frozen_string_literal: true

class Referentiels::ResponseRendererComponent < ViewComponent::Base
  attr_reader :referentiel, :referentiel_service
  delegate :test_url, :test_headers, to: :referentiel_service

  def initialize(referentiel:)
    @referentiel = referentiel
    @referentiel_service = ReferentielService.new(referentiel: referentiel)
  end
end
