# frozen_string_literal: true

class Instructeurs::ColumnFilterValueComponent < ApplicationComponent
  attr_reader :column, :form

  def initialize(column:, form:)
    @column = column
    @form = form
  end

  def column_filter_options
    options = column.options_for_select

    if !@column.mandatory
      options.unshift(Column.not_provided_option)
    end

    options
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
