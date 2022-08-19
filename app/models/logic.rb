module Logic
  def self.from_h(h)
    class_from_name(h['term']).from_h(h)
  end

  def self.from_json(s)
    from_h(JSON.parse(s))
  end

  def self.class_from_name(name)
    [ChampValue, Constant, Empty, LessThan, LessThanEq, Eq, GreaterThanEq, GreaterThan, EmptyOperator, And, Or]
      .find { |c| c.name == name }
  end

  def self.ensure_compatibility_from_left(condition)
    left = condition.left
    right = condition.right
    operator_class = condition.class

    case [left.type, condition]
    in [:boolean, _]
      operator_class = Eq
    in [:empty, _]
      operator_class = EmptyOperator
    in [:enum, _]
      operator_class = Eq
    in [:number, EmptyOperator]
      operator_class = Eq
    in [:number, _]
    end

    if !compatible_type?(left, right)
      right = case left.type
      when :boolean
        Constant.new(true)
      when :empty
        Empty.new
      when :enum
        Constant.new(left.options.first)
      when :number
        Constant.new(0)
      end
    end

    operator_class.new(left, right)
  end

  def self.compatible_type?(left, right)
    case [left.type, right.type]
    in [a, ^a] # syntax for same type
      true
    in [:enum, :string]
      left.options.include?(right.value)
    else
      false
    end
  end

  def self.add_empty_condition_to(condition)
    empty_condition = EmptyOperator.new(Empty.new, Empty.new)

    if condition.nil?
      empty_condition
    elsif [And, Or].include?(condition.class)
      condition.tap { |c| c.operands << empty_condition }
    else
      Logic::And.new([condition, empty_condition])
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
