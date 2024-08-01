# frozen_string_literal: true

class Logic::NotInDepartementOperator < Logic::InDepartementOperator
  def operation
    :n_est_pas_dans_le_departement
  end

  def compute(champs = [])
    l = @left.compute(champs)
    r = @right.compute(champs)

    return false if l.nil?

    l.fetch(:code_departement) != r
  end
end
