# frozen_string_literal: true

class Columns::ChampColumn < Column
  attr_reader :stable_id

  def initialize(procedure_id:, label:, stable_id:, tdc_type:, displayable: true, filterable: true, type: :text, value_column: :value)
    @stable_id = stable_id
    @tdc_type = tdc_type

    super(
      procedure_id:,
      table: 'type_de_champ',
      column: stable_id.to_s,
      label:,
      type:,
      value_column:,
      displayable:,
      filterable:
    )
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

  def column_id = "type_de_champ/#{stable_id}"

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

  def parse_enums(value) = JSON.parse(value) rescue nil

  def parse_datetime(value) = Time.zone.parse(value) rescue nil
end
