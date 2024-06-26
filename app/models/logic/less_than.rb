class Logic::LessThan < Logic::BinaryOperator
  def operation = :<

  def sql_condition(types_de_champ = [])
    Champ.arel_table[:value].lt(@right.to_s)
  end
end
