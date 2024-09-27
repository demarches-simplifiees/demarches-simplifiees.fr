# frozen_string_literal: true

class FilteredColumn
  attr_reader :column, :filter

  def initialize(column:, filter:)
    @column = column
    @filter = filter
  end

  def ==(other)
    other&.column == column && other.filter == filter
  end
end
