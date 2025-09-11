# frozen_string_literal: true

class Instructeurs::EditableFiltersComponent < ApplicationComponent
  attr_reader :procedure_presentation, :statut, :instructeur_procedure

  def initialize(procedure_presentation:, instructeur_procedure:, statut:)
    @procedure_presentation = procedure_presentation
    @instructeur_procedure = instructeur_procedure
    @statut = statut
  end

  def render?
    filters.any?
  end

  def filters
    @procedure_presentation.filters_for(statut)
  end
end
