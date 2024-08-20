class Instructeurs::ColumnPickerComponent < ApplicationComponent
  attr_reader :procedure, :procedure_presentation

  def initialize(procedure:, procedure_presentation:)
    @procedure = procedure
    @procedure_presentation = procedure_presentation
    @displayable_columns_for_select, @displayable_columns_selected = displayable_columns_for_select
  end

  def displayable_columns_for_select
    [
      procedure.columns.reject(&:virtual).map { |column| [column.label, column.id] },
      procedure_presentation.displayed_fields.map { Column.new(**_1.deep_symbolize_keys).id }
    ]
  end
end
