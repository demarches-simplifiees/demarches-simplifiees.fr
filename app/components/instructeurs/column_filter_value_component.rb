# frozen_string_literal: true

class Instructeurs::ColumnFilterValueComponent < ApplicationComponent
  attr_reader :column

  def initialize(column:)
    @column = column
  end

  def call
    if column.nil?
      tag.input(id: 'value', class: 'fr-input', disabled: true)
    elsif column.type.in?([:enum, :enums, :boolean])
      select_tag 'filters[][filter]',
        options_for_select(column.options_for_select),
        id: 'value',
        class: 'fr-select',
        data: { no_autosubmit: true },
        required: true
    else
      tag.input(
        name: "filters[][filter]",
        id: 'value',
        class: 'fr-input',
        type:,
        maxlength: FilteredColumn::FILTERS_VALUE_MAX_LENGTH,
        data: { no_autosubmit: true },
        required: true
      )
    end
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
