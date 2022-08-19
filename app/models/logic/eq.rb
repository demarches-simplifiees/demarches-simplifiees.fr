class Logic::Eq < Logic::BinaryOperator
  def operation = :==

  def errors(stable_ids = [])
    errors = []

    if !Logic.compatible_type?(@left, @right)
      errors += ["les types sont incompatibles : #{self}"]
    end

    errors + @left.errors(stable_ids) + @right.errors(stable_ids)
  end

  def ==(other)
    self.class == other.class &&
      [@left, @right].permutation.any? { |p| p == [other.left, other.right] }
  end
end
