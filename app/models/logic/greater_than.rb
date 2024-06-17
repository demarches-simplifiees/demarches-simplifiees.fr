class Logic::GreaterThan < Logic::BinaryOperator
  def operation = :>

  def sql_condition(types_de_champ = [])
    Champ.arel_table[:value].gt(@right.to_s)
  end
end
