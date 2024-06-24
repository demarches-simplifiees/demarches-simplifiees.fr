class Logic::NotInArchipelOperator < Logic::InArchipelOperator
  def operation
    :n_est_pas_dans_l_archipel
  end

  def compute(champs)
    l = @left.compute(champs)
    r = @right.compute(champs)

    return false if l.nil?

    l.fetch(:archipel) != r
  end
end
