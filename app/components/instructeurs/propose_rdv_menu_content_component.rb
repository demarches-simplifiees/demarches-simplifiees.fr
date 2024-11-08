# frozen_string_literal: true

class Instructeurs::ProposeRdvMenuContentComponent < ApplicationComponent
  def initialize(dossier:, has_plage_ouvertures:)
    @dossier = dossier
    @has_plage_ouvertures = has_plage_ouvertures
  end
end
