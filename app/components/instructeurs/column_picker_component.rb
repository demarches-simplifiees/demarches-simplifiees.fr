class Instructeurs::ColumnPickerComponent < ApplicationComponent
  attr_reader :procedure, :procedure_presentation

  def initialize(procedure:, procedure_presentation:)
    @procedure = procedure
    @procedure_presentation = procedure_presentation
    @displayable_fields_for_select, @displayable_fields_selected = displayable_fields_for_select
  end

  def displayable_fields_for_select
    [
      procedure.facets.reject(&:virtual).map { |facet| [facet.label, facet.id] },
      procedure_presentation.displayed_fields.map { Facet.new(**_1.deep_symbolize_keys).id }
    ]
  end
end
