class Logic::NotEq < Logic::Eq
  def operation = :!=

  def sql_condition(types_de_champ = [])
    Champ.arel_table[:value].not_eq(@right.to_s)
  end
end
