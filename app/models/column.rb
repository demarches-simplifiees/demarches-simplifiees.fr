# frozen_string_literal: true

class Column
  TYPE_DE_CHAMP_TABLE = 'type_de_champ'

  attr_reader :table, :column, :label, :type, :scope, :value_column, :filterable, :displayable

  def initialize(procedure_id:, table:, column:, label: nil, type: :text, value_column: :value, filterable: true, displayable: true, scope: '')
    @procedure_id = procedure_id
    @table = table
    @column = column
    @label = label || I18n.t(column, scope: [:activerecord, :attributes, :procedure_presentation, :fields, table])
    @type = type
    @scope = scope
    @value_column = value_column
    @filterable = filterable
    @displayable = displayable
  end

  # the id is a String to be used in forms
  def id = h_id.to_json

  # the h_id is a Hash and hold enough information to find the column
  # in the ColumnType class, aka be able to do the h_id -> column conversion
  def h_id = { procedure_id: @procedure_id, column_id: "#{table}/#{column}" }

  def ==(other) = h_id == other.h_id # using h_id instead of id to avoid inversion of keys

  def to_json
    {
      table:, column:, label:, type:, scope:, value_column:, filterable:, displayable:
    }
  end

  def notifications? = [table, column] == ['notifications', 'notifications']

  def dossier_state? = [table, column] == ['self', 'state']

  def self.find(h_id)
    Procedure.with_discarded.find(h_id[:procedure_id]).find_column(h_id:)
  end
end
