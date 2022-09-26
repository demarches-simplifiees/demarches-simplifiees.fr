class Logic::Eq < Logic::BinaryOperator
  def operation = :==

  def errors(stable_ids = [])
    errors = [@left, @right]
      .filter { |term| term.type == :unmanaged }
      .map { |term| { type: :unmanaged, stable_id: term.stable_id } }

    if !Logic.compatible_type?(@left, @right)
      errors << {
        type: :incompatible,
        stable_id: @left.try(:stable_id),
        right: @right,
        operator_name: self.class.name
      }
    elsif @left.type == :enum &&
      !left.options.map(&:second).include?(right.value)
      errors << {
        type: :not_included,
        stable_id: @left.stable_id,
        right: @right
      }
    end

    errors + @left.errors(stable_ids) + @right.errors(stable_ids)
  end

  def ==(other)
    self.class == other.class &&
      [@left, @right].permutation.any? { |p| p == [other.left, other.right] }
  end
end
