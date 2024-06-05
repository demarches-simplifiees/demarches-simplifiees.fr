class Logic::And < Logic::NAryOperator
  attr_reader :operands

  def operator_name = 'Et'

  def compute(champs = [])
    @operands.map { |operand| operand.compute(champs) }.all?
  end

  def computable?(champs = [])
    return true if sources.blank?

    champs.filter { _1.stable_id.in?(sources) && _1.visible? }
      .all? { _1.value.present? }
  end

  def to_s(type_de_champs) = "(#{@operands.map { |o| o.to_s(type_de_champs) }.join(' && ')})"
end
