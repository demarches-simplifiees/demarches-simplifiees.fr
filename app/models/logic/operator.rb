# frozen_string_literal: true

class Logic::Operator < Logic::Term
  attr_reader :operands

  def hash
    term = self.class.name
    sorted_operands = operands.sort_by(&:hash)
    [term, *sorted_operands].hash
  end
end
