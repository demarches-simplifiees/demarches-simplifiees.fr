class Logic::Or < Logic::NAryOperator
  attr_reader :operands

  def operator_name = 'Ou'

  def compute(champs = [])
    @operands.map { |operand| operand.compute(champs) }.any?
  end

  def to_s(type_de_champs = []) = "(#{@operands.map { |o| o.to_s(type_de_champs) }.join(' || ')})"

  def to_query(types_de_champs = [])
    query = nil

    @operands.each do |operand|
      base_query = Champ.where(stable_id: operand.left.sources).where(operand.sql_condition(types_de_champs))
      if query
        query = query.or(base_query)
      else
        query = base_query
      end
    end
    query
  end
end
