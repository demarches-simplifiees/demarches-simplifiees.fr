class Logic::InArchipelOperator < Logic::BinaryOperator
  def operation
    :est_dans_l_archipel
  end

  def compute(champs)
    l = @left.compute(champs)
    r = @right.compute(champs)

    return false if l.nil?

    l.fetch(:archipel) == r
  end

  def errors(type_de_champs = [])
    @left.errors(type_de_champs) + @right.errors(type_de_champs)
  end
end
