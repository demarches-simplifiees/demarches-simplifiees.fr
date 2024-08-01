# frozen_string_literal: true

class Logic::IncludeOperator < Logic::BinaryOperator
  def operation = :include?

  def errors(type_de_champs = [])
    result = []

    if left_not_a_list?(type_de_champs)
      result << { type: :required_list }
    elsif right_value_not_in_list?(type_de_champs)
      result << {
        type: :not_included,
        stable_id: @left.stable_id,
        right: @right
      }
    end

    result + @left.errors(type_de_champs) + @right.errors(type_de_champs)
  end

  private

  def left_not_a_list?(type_de_champs)
    @left.type(type_de_champs) != :enums
  end

  def right_value_not_in_list?(type_de_champs)
    !@left.options(type_de_champs).map(&:second).include?(@right.value)
  end
end
