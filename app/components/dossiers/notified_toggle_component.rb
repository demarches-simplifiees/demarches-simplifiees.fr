# frozen_string_literal: true

class Dossiers::NotifiedToggleComponent < ApplicationComponent
  def initialize(procedure_presentation:)
    @procedure_presentation = procedure_presentation
    @procedure = procedure_presentation.procedure
    @sorted_column = procedure_presentation.sorted_column
  end
end
