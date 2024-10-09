# frozen_string_literal: true

class SortedColumn
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
