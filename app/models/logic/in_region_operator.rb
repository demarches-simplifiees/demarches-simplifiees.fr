# frozen_string_literal: true

class Logic::InRegionOperator < Logic::BinaryOperator
  def operation
    :est_dans_la_region
  end

  def compute(champs)
    l = @left.compute(champs)
    r = @right.compute(champs)

    return false if l.nil?

    l.fetch(:code_region) == r
  end

  def errors(type_de_champs = [])
    @left.errors(type_de_champs) + @right.errors(type_de_champs)
  end
end
