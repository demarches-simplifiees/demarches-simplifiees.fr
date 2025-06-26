# frozen_string_literal: true

class Instructeurs::ColumnFilterValueComponent < ApplicationComponent
  attr_reader :column

  def initialize(column:)
    @column = column
  end

  def as_radio_button?
    column.respond_to?(:tdc_type) && column.tdc_type.in?(["yes_no"])
  end

  private

  def type
    case column.type
    when :datetime, :date
      'date'
    when :integer, :decimal
      'number'
    else
      'text'
    end
  end
end
