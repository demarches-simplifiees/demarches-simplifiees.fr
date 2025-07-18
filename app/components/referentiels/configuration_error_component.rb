# frozen_string_literal: true

class Referentiels::ConfigurationErrorComponent < Referentiels::MappingFormBase
  attr_reader :referentiel_service
  delegate :test_url, :test_headers, to: :referentiel_service
  def initialize(**args)
    super
    @referentiel_service = ReferentielService.new(referentiel: referentiel)
  end

  def error_title
    "¡Ay, caramba! 💣💥"
  end
end
