# frozen_string_literal: true

class Instructeurs::AddFilterDropdownComponent < ApplicationComponent
  attr_reader :procedure_presentation, :statut, :instructeur_procedure

  def initialize(procedure_presentation:, statut:, instructeur_procedure:)
    @procedure_presentation = procedure_presentation
    @statut = statut
    @instructeur_procedure = instructeur_procedure
  end
end
