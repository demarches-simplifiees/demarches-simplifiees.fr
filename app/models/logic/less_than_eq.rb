class Logic::LessThanEq < Logic::BinaryOperator
  def operation = :<=

  def sql_condition(types_de_champ = [])
    Champ.arel_table[:value].lteq(@right.to_s)
  end
end
