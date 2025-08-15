# frozen_string_literal: true

class Instructeurs::ColumnFilterValueComponent < ApplicationComponent
  attr_reader :column, :form, :instructeur_procedure

  def initialize(column:, form:, instructeur_procedure:)
    @column = column
    @form = form
    @instructeur_procedure = instructeur_procedure
  end

  def column_filter_options
    options = column.options_for_select

    if tdc_type == "yes_no" && !column.mandatory
      options.unshift(Column.not_filled_option)
    end

    if column.column == 'notification_type'
      options.filter! do |label, type|
        @instructeur_procedure.notification_preference_for(type) != 'none'
      end
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
