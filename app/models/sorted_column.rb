# frozen_string_literal: true

class SortedColumn
  # include validations to enable procedure_presentation.validate_associate,
  # which enforces the deserialization of columns in the sorted_column attribute
  # and raises an error if a column is not found
  include ActiveModel::Validations

  attr_reader :column, :order

  def initialize(column:, order:)
    @column = column
    @order = order
  end

  def ascending? = @order == 'asc'

  def opposite_order = ascending? ? 'desc' : 'asc'

  def ==(other)
    other&.column == column && other.order == order
  end

  def sort_by_notifications?
    @column.notifications? && @order == 'desc'
  end
end
