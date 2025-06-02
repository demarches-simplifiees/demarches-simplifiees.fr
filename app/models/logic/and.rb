# frozen_string_literal: true

class Logic::And < Logic::NAryOperator
  attr_reader :operands

  def operator_name = 'Et'

  def compute(champs = [])
    @operands.map { |operand| operand.compute(champs) }.all?
  end

  def to_s(type_de_champs) = "(#{@operands.map { |o| o.to_s(type_de_champs) }.join(' && ')})"
end
