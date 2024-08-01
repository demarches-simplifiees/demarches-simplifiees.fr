# frozen_string_literal: true

class Procedure::GroupesAjoutComponent < ApplicationComponent
  def initialize(procedure:, groupe_instructeurs:)
    @procedure = procedure
    @groupe_instructeurs = groupe_instructeurs
  end
end
