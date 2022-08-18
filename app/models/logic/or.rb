class Logic::Or < Logic::NAryOperator
  attr_reader :operands

  def operator_name = 'Ou'

  def compute(champs = [])
    @operands.map { |operand| operand.compute(champs) }.any?
  end

  def to_s = "(#{@operands.map(&:to_s).join(' || ')})"
end
