# frozen_string_literal: true

class Logic::NotInRegionOperator < Logic::InRegionOperator
  def operation
    :n_est_pas_dans_la_region
  end

  def compute(champs)
    l = @left.compute(champs)
    r = @right.compute(champs)

    return false if l.nil?

    l.fetch(:code_region) != r
  end
end
