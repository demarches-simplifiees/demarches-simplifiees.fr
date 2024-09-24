# frozen_string_literal: true

class Instructeurs::ColumnTableHeaderComponent < ApplicationComponent
  def initialize(procedure_presentation:)
    @procedure_presentation = procedure_presentation
    @columns = procedure_presentation.displayed_fields_for_headers
    @sorted_column = procedure_presentation.sorted_column
  end

  def label_and_arrow(column)
    return column.label if @sorted_column.column != column

    @sorted_column.ascending? ? "#{column.label} ↑" : "#{column.label} ↓"
  end

  def aria_sort(column)
    return {} if @sorted_column.column != column

    @sorted_column.ascending? ? { "aria-sort": "ascending" } : { "aria-sort": "descending" }
  end
end
