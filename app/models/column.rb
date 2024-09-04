# frozen_string_literal: true

class Column
  attr_reader :table, :column, :label, :classname, :type, :scope, :value_column, :filterable, :displayable

  def initialize(table:, column:, label: nil, type: :text, value_column: :value, filterable: true, displayable: true, classname: '', scope: '')
    @table = table
    @column = column
    @label = label || I18n.t(column, scope: [:activerecord, :attributes, :procedure_presentation, :fields, table])
    @classname = classname
    @type = type
    @scope = scope
    @value_column = value_column
    @filterable = filterable
    # We need this for backward compatibility
    @displayable = displayable
  end

  def id
    "#{table}/#{column}"
  end

  def self.make_id(table, column)
    "#{table}/#{column}"
  end

  def ==(other)
    other.to_json == to_json
  end

  def to_json
    {
      table:, column:, label:, classname:, type:, scope:, value_column:, filterable:, displayable:
    }
  end
end
