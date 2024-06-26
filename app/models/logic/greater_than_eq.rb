class Logic::GreaterThanEq < Logic::BinaryOperator
  def operation = :>=

  def sql_condition(types_de_champ = [])
    Champ.arel_table[:value].gteq(@right.to_s)
  end
end
