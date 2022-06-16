module Logic
  def self.from_h(h)
    class_from_name(h['op']).from_h(h)
  end

  def self.from_json(s)
    from_h(JSON.parse(s))
  end

  def self.class_from_name(name)
    [ChampValue, Constant, Empty, LessThan, LessThanEq, Eq, GreaterThanEq, GreaterThan, EmptyOperator, And, Or]
      .find { |c| c.name == name }
  end

  def self.compatible_type?(left, right)
    case [left.type, right.type]
    in [a, ^a] # syntax for same type
      true
    else
      false
    end
  end

  def ds_eq(left, right) = Logic::Eq.new(left, right)

  def greater_than(left, right) = Logic::GreaterThan.new(left, right)

  def greater_than_eq(left, right) = Logic::GreaterThanEq.new(left, right)

  def less_than(left, right) = Logic::LessThan.new(left, right)

  def less_than_eq(left, right) = Logic::LessThanEq.new(left, right)

  def constant(value) = Logic::Constant.new(value)

  def champ_value(stable_id) = Logic::ChampValue.new(stable_id)

  def empty = Logic::Empty.new

  def empty_operator(left, right) = Logic::EmptyOperator.new(left, right)

  def ds_or(operands) = Logic::Or.new(operands)

  def ds_and(operands) = Logic::And.new(operands)
end
