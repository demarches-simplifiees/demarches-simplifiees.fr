# frozen_string_literal: true

class Logic::Or < Logic::NAryOperator
  attr_reader :operands

  def operator_name = 'Ou'

  def compute(champs = [])
    @operands.map { |operand| operand.compute(champs) }.any?
  end

  def to_s(type_de_champs = []) = "(#{@operands.map { |o| o.to_s(type_de_champs) }.join(' || ')})"
end
