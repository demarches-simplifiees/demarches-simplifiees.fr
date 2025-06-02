# frozen_string_literal: true

class Instructeurs::ColumnTableHeaderComponent < ApplicationComponent
  attr_reader :procedure_presentation, :column
  # maybe extract a ColumnSorter class?
  #

  def initialize(procedure_presentation:, column:)
    @procedure_presentation = procedure_presentation
    @column = column
  end

  def column_id
    column.id
  end

  def sorted_by_current_column?
    procedure_presentation.sort['table'] == column.table &&
    procedure_presentation.sort['column'] == column.column
  end

  def sorted_ascending?
    current_sort_order == 'asc'
  end

  def sorted_descending?
    current_sort_order == 'desc'
  end

  def aria_sort
    if sorted_by_current_column?
      if sorted_ascending?
        { "aria-sort": "ascending" }
      elsif sorted_descending?
        { "aria-sort": "descending" }
      end
    else
      {}
    end
  end

  private

  def current_sort_order
    procedure_presentation.sort['order']
  end
end
