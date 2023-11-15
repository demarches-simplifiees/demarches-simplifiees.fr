class Logic::ExcludeOperator < Logic::IncludeOperator
  def operation = :exclude?
end
