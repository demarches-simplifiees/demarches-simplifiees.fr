class Logic::Eq < Logic::BinaryOperator
  def operation = :==

  def errors(type_de_champs = [])
    errors = [@left, @right]
      .filter { |term| term.type(type_de_champs) == :unmanaged }
      .map { |term| { type: :unmanaged, stable_id: term.stable_id } }

    if !Logic.compatible_type?(@left, @right)
      errors << {
        type: :incompatible,
        stable_id: @left.try(:stable_id),
        right: @right,
        operator_name: self.class.name
      }
    elsif @left.type(type_de_champs) == :enum &&
      !left.options(type_de_champs).map(&:second).include?(right.value)
      errors << {
        type: :not_included,
        stable_id: @left.stable_id,
        right: @right
      }
    end

    errors + @left.errors(type_de_champs) + @right.errors(type_de_champs)
  end

  def ==(other)
    self.class == other.class &&
      [@left, @right].permutation.any? { |p| p == [other.left, other.right] }
  end
end
