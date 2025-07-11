# frozen_string_literal: true

class Instructeurs::ColumnFilterValueComponent < ApplicationComponent
  attr_reader :column, :form

  def initialize(column:, form:)
    @column = column
    @form = form
  end

  def column_filter_options
    options = column.options_for_select

    if tdc_type == "yes_no" && !column.mandatory
      options.unshift(Column.not_filled_option)
    end

    options
  end

  def tdc_type
    column.tdc_type if column.respond_to?(:tdc_type)
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
