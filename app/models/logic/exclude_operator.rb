# frozen_string_literal: true

class Logic::ExcludeOperator < Logic::IncludeOperator
  def operation = :exclude?
end
