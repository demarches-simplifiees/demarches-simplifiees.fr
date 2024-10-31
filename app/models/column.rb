# frozen_string_literal: true

class Column
  # include validations to enable procedure_presentation.validate_associate,
  # which enforces the deserialization of columns in the displayed_columns attribute
  # and raises an error if a column is not found
  include ActiveModel::Validations

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
  def groupe_instructeur? = [table, column] == ['groupe_instructeur', 'id']
  def type_de_champ? = table == TYPE_DE_CHAMP_TABLE

  def self.find(h_id)
    begin
      procedure = Procedure.with_discarded.find(h_id[:procedure_id])
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound.new("Column: unable to find procedure #{h_id[:procedure_id]} from h_id #{h_id}")
    end

    procedure.find_column(h_id: h_id)
  end

  def value(champ)
    return if champ.nil?

    value = typed_value(champ)
    if default_column?
      cast_value(value, from_type: champ.last_write_column_type, to_type: type)
    else
      value
    end
  end

  private

  def typed_value(champ)
    value = string_value(champ)
    parse_value(value, type: champ.last_write_column_type)
  end

  def string_value(champ) = champ.public_send(value_column)
  def default_column? = value_column.in?([:value, :external_id])

  def parse_value(value, type:)
    return if value.blank?

    case type
    when :boolean
      parse_boolean(value)
    when :integer
      value.to_i
    when :decimal
      value.to_f
    when :datetime
      parse_datetime(value)
    when :date
      parse_datetime(value)&.to_date
    when :enums
      parse_enums(value)
    else
      value
    end
  end

  def cast_value(value, from_type:, to_type:)
    return if value.blank?
    return value if from_type == to_type

    case [from_type, to_type]
    when [:integer, :decimal] # recast numbers automatically
      value.to_f
    when [:decimal, :integer] # may lose some data, but who cares ?
      value.to_i
    when [:integer, :text], [:decimal, :text] # number to text
      value.to_s
    when [:enum, :enums] # single list can become multi
      [value]
    when [:enum, :text] # single list can become text
      value
    when [:enums, :enum] # multi list can become single list
      value.first
    when [:enums, :text] # multi list can become text
      value.join(', ')
    when [:date, :datetime] # date <=> datetime
      value.to_datetime
    when [:datetime, :date] # may lose some data, but who cares ?
      value.to_date
    else
      nil
    end
  end

  def parse_boolean(value)
    case value
    when 'true', 'on', '1'
      true
    when 'false'
      false
    end
  end

  def parse_enums(value)
    JSON.parse(value)
  rescue JSON::ParserError
    nil
  end

  def parse_datetime(value)
    Time.zone.parse(value)
  rescue ArgumentError
    nil
  end
end
