# frozen_string_literal: true

class Dossiers::FormattedDateWithBadgeComponent < ApplicationComponent
  attr_reader :etablissement

  def initialize(etablissement:)
    @etablissement = etablissement
  end

  def date_creation
    helpers.try_format_date(etablissement.entreprise.date_creation)
  end

  def badge_class
    helpers.entreprise_etat_administratif_badge_class(etablissement)
  end

  def badge_content
    helpers.humanized_entreprise_etat_administratif(etablissement)
  end
end
