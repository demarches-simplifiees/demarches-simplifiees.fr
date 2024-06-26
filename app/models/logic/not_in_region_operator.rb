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

  def sql_condition(types_de_champ = [])
    Champ.arel_table[:external_id].not_eq(@right.to_s)
  end
end
