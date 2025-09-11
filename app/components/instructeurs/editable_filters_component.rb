# frozen_string_literal: true

class Instructeurs::EditableFiltersComponent < ApplicationComponent
  attr_reader :procedure_presentation, :statut

  def initialize(procedure_presentation:, statut:)
    @procedure_presentation = procedure_presentation
    @statut = statut
  end

  def render?
    filters.any?
  end

  def filters
    @procedure_presentation.filters_for(statut)
  end
end
