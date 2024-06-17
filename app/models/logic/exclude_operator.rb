class Logic::ExcludeOperator < Logic::IncludeOperator
  def operation = :exclude?

  def sql_condition(types_de_champ = [])
    Champ.arel_table[:value].does_not_match("%#{Champ.sanitize_sql_like(@right.to_s)}%")
  end
end
