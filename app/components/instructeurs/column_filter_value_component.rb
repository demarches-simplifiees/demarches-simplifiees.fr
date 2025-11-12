# frozen_string_literal: true

class Instructeurs::ColumnFilterValueComponent < ApplicationComponent
  attr_reader :filtered_column, :form, :instructeur_procedure

  def initialize(filtered_column:, form:, instructeur_procedure:)
    @filtered_column = filtered_column
    @form = form
    @instructeur_procedure = instructeur_procedure
  end

  def id
    # unique id to avoid turbo-frame reload
    "#{filtered_column.id.parameterize}_column_filter_value_component"
  end

  def operator_hidden_field
    return nil if is_date?

    @form.hidden_field "filter[filter][operator]", value: 'match'
  end

  def column
    filtered_column&.column
  end

  def label
    filtered_column&.label
  end

  def value
    filtered_column&.filter_value
  end

  def operator
    filtered_column&.filter_operator || "match"
  end

  def column_filter_options
    options = column.options_for_select

    if tdc_type == "yes_no" && !column.mandatory
      options.unshift(Column.not_filled_option)
    end

    if column.column == 'notification_type'
      options.filter! do |_, type|
        @instructeur_procedure&.notification_preference_for(type) != 'none'
      end
    end

    options
  end

  def radio_button_options
    column_filter_options.map.with_index do |(opt_label, opt_value)|
      {
        label: opt_label,
        value: opt_value,
        checked: opt_value.to_s.in?(value),
        id: input_id(value: opt_value),
        data: { turbo_force: :server },
      }
    end
  end

  def date_filter_options
    ['match', 'before', 'after', 'this_week', 'this_month', 'this_year']
      .map { |operator| [t(".operators.#{operator}"), operator] }
  end

  def tdc_type
    column.tdc_type if column.respond_to?(:tdc_type)
  end

  def is_date?
    column&.type&.in?([:datetime, :date])
  end

  def is_operator_with_value?
    return true if !is_date?

    filtered_column.filter_operator.in?(["before", "after", "match"])
  end

  def selectable?
    column&.type&.in?([:enum, :enums])
  end

  def boolean?
    column&.type&.in?([:boolean])
  end

  def react_props
    {
      id: input_id,
      class: 'fr-mt-1w',
      name: 'filter[filter][value][]',
      items: column_filter_options,
      value_separator: false,
      selected_keys: filtered_column&.filter_value,
    }
  end

  def input_id(value: nil)
    ["value", filtered_column&.id&.parameterize, value].compact.join('_')
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
