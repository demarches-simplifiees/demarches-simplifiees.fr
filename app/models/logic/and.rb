class Logic::And < Logic::NAryOperator
  attr_reader :operands

  def operator_name = 'Et'

  def compute(champs = [])
    @operands.map { |operand| operand.compute(champs) }.all?
  end

  def to_s = "(#{@operands.map(&:to_s).join(' && ')})"
end
