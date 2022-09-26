class Logic::IncludeOperator < Logic::BinaryOperator
  def operation = :include?

  def errors(stable_ids = [])
    result = []

    if left_not_a_list?(type_de_champs)
      result << { type: :required_list }
    elsif right_value_not_in_list?
      result << {
        type: :not_included,
        stable_id: @left.stable_id,
        right: @right
      }
    end

    result + @left.errors(stable_ids) + @right.errors(stable_ids)
  end

  private

  def left_not_a_list?(type_de_champs)
    @left.type(type_de_champs) != :enums
  end

  def right_value_not_in_list?
    !@left.options.map(&:second).include?(@right.value)
  end
end
