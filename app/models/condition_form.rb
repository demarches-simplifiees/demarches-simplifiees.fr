# frozen_string_literal: true

class ConditionForm
  include ActiveModel::Model
  include Logic

  attr_accessor :top_operator_name, :rows, :source_tdcs

  def to_condition
    case sub_conditions.count
    when 0
      nil
    when 1
      sub_conditions.first
    else
      top_operator_class.new(sub_conditions)
    end
  end

  def delete_row(i)
    rows.slice!(i)

    self
  end

  def change_champ(i)
    sub_conditions[i] = Logic.ensure_compatibility_from_left(sub_conditions[i], source_tdcs)

    self
  end

  private

  def top_operator_class
    Logic.class_from_name(top_operator_name)
  end

  def sub_conditions
    @sub_conditions ||= rows.map { |row| row_to_condition(row) }
  end

  def row_to_condition(row)
    left = Logic.from_json(row[:targeted_champ])
    right = parse_value(left.type(source_tdcs), row[:value])

    Logic.class_from_name(row[:operator_name]).new(left, right)
  end

  def parse_value(left_type, value)
    return empty if value.blank?

    if left_type == :number || left_type == :integer || left_type == :decimal
      # in this special case, we try to cast as Float, then Integer
      # but it can still be a previous string value or a mistap
      number = parse_to_number(value)

      return constant(number) if number
    end

    # otherwise it can be a serialized Constant(true | false) term
    # or a serialized Empty term
    term = Logic.from_json(value) rescue nil
    return term if term.present?

    # if anything else, save it as a constant of string
    constant(value)
  end

  def parse_to_number(str)
    float = Float(str)
    float % 1 == 0 ? float.to_i : float
  rescue ArgumentError
    nil
  end
end
