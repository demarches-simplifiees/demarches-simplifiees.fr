# frozen_string_literal: true

class Logic::InDepartementOperator < Logic::BinaryOperator
  def operation
    :est_dans_le_departement
  end

  def compute(champs = [])
    l = @left.compute(champs)
    r = @right.compute(champs)

    return false if l.nil?

    l.fetch(:code_departement) == r
  end

  def errors(type_de_champs = [])
    @left.errors(type_de_champs) + @right.errors(type_de_champs)
  end
end
