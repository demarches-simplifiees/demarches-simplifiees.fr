# frozen_string_literal: true

class Column
  TYPE_DE_CHAMP_TABLE = 'type_de_champ'

  attr_reader :table, :column, :label, :classname, :type, :scope, :value_column, :filterable, :displayable

  def initialize(procedure_id:, table:, column:, label: nil, type: :text, value_column: :value, filterable: true, displayable: true, classname: '', scope: '')
    @procedure_id = procedure_id
    @table = table
    @column = column
    @label = label || I18n.t(column, scope: [:activerecord, :attributes, :procedure_presentation, :fields, table])
    @classname = classname
    @type = type
    @scope = scope
    @value_column = value_column
    @filterable = filterable
    @displayable = displayable
  end

  def id = h_id.to_json
  def h_id = { procedure_id: @procedure_id, column_id: "#{table}/#{column}" }
  def ==(other) = h_id == other.h_id # using h_id instead of id to avoid inversion of keys

  def to_json
    {
      table:, column:, label:, classname:, type:, scope:, value_column:, filterable:, displayable:
    }
  end
end
