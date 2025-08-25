# frozen_string_literal: true

class Instructeurs::ColumnFilterValueComponent < ApplicationComponent
  attr_reader :column, :form

  def initialize(column:, form:)
    @column = column
    @form = form
  end

  def operator_hidden_field
    @form.hidden_field "filter[filter][operator]", value: selectable? ? 'in' : 'match'
  end

  def column_filter_options
    options = column.options_for_select

    if tdc_type == "yes_no" && !column.mandatory
      options.unshift(Column.not_filled_option)
    end

    options
  end

  def date_filter_options
    [
      [t('.operator_le'), 'match'],
      [t('.operator_before'), 'before'],
      [t('.operator_after'), 'after'],
      [t('.operator_this_week'), 'this_week'],
      [t('.operator_this_month'), 'this_month'],
      [t('.operator_this_year'), 'this_year']
    ]
  end

  def tdc_type
    column.tdc_type if column.respond_to?(:tdc_type)
  end

  def is_date?
    column&.type&.in?([:datetime, :date])
  end

  def selectable?
    column&.type&.in?([:enum, :enums])
  end

  def boolean?
    column&.type&.in?([:boolean])
  end

  def react_props
    {
      id: 'value',
      class: 'fr-mt-1w',
      name: 'filter[filter][value][]',
      items: column_filter_options,
      value_separator: false
    }
  end

  private

  def type
    case column&.type
    when :datetime, :date
      'date'
    when :integer, :decimal
      'number'
    else
      'text'
    end
  end
end
