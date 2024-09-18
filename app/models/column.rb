# frozen_string_literal: true

class Column
  TYPE_DE_CHAMP_TABLE = 'type_de_champ'

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
    @displayable = displayable
    @id_value_h = {}
  end

  def id
    "#{table}/#{column}"
  end

  def same_stable_id?(stable_id:)
    column.to_s == stable_id.to_s
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

  def add_value(id, val)
    @id_value_h[id] = val
  end

  def set_id_value_h(id_value_h)
    @id_value_h = id_value_h
  end

  def id_value_h
    @id_value_h
  end
end
