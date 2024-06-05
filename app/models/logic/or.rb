class Logic::Or < Logic::NAryOperator
  attr_reader :operands

  def operator_name = 'Ou'

  def compute(champs = [])
    @operands.map { |operand| operand.compute(champs) }.any?
  end


  def computable?(champs = [])
    return true if sources.blank?

    visible_champs_sources = champs.filter { _1.stable_id.in?(sources) && _1.visible? }

    return false if visible_champs_sources.blank?
    visible_champs_sources.all? { _1.value.present? } || compute(visible_champs_sources)
  end

  def to_s(type_de_champs = []) = "(#{@operands.map { |o| o.to_s(type_de_champs) }.join(' || ')})"
end
