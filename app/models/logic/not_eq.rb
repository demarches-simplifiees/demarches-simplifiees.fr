# frozen_string_literal: true

class Logic::NotEq < Logic::Eq
  def operation = :!=
end
