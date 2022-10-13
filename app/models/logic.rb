module Logic
  def self.from_h(h)
    class_from_name(h['term']).from_h(h)
  end

  def self.from_json(s)
    from_h(JSON.parse(s))
  end

  def self.from_expression(expression)
    from_h(ExpressionParser.parse(expression).deep_stringify_keys)
  end

  def self.class_from_name(name)
    [ChampValue, Constant, Empty, LessThan, LessThanEq, Eq, NotEq, GreaterThanEq, GreaterThan, EmptyOperator, IncludeOperator, And, Or]
      .find { |c| c.name == name }
  end

  def self.ensure_compatibility_from_left(condition, type_de_champs)
    left = condition.left
    right = condition.right
    operator_class = condition.class

    case [left.type(type_de_champs), condition]
    in [:boolean, _]
      operator_class = Eq
    in [:empty, _]
      operator_class = EmptyOperator
    in [:enum, _]
      operator_class = Eq
    in [:enums, _]
      operator_class = IncludeOperator
    in [:number, EmptyOperator]
      operator_class = Eq
    in [:number, _]
    end

    if !compatible_type?(left, right, type_de_champs)
      right = case left.type(type_de_champs)
      when :boolean
        Constant.new(true)
      when :empty
        Empty.new
      when :enum, :enums
        Constant.new(left.options(type_de_champs).first.second)
      when :number
        Constant.new(0)
      end
    end

    operator_class.new(left, right)
  end

  def self.compatible_type?(left, right, type_de_champs)
    case [left.type(type_de_champs), right.type(type_de_champs)]
    in [a, ^a] # syntax for same type
      true
    in [:enum, :string] | [:enums, :string]
      true
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

  def self.split_condition(condition)
    [condition.left, condition.class.name, condition.right]
  end

  def ds_eq(left, right) = Logic::Eq.new(left, right)

  def ds_not_eq(left, right) = Logic::NotEq.new(left, right)

  def greater_than(left, right) = Logic::GreaterThan.new(left, right)

  def greater_than_eq(left, right) = Logic::GreaterThanEq.new(left, right)

  def less_than(left, right) = Logic::LessThan.new(left, right)

  def less_than_eq(left, right) = Logic::LessThanEq.new(left, right)

  def ds_include(left, right) = Logic::IncludeOperator.new(left, right)

  def constant(value) = Logic::Constant.new(value)

  def champ_value(stable_id) = Logic::ChampValue.new(stable_id)

  def empty = Logic::Empty.new

  def empty_operator(left, right) = Logic::EmptyOperator.new(left, right)

  def ds_or(operands) = Logic::Or.new(operands)

  def ds_and(operands) = Logic::And.new(operands)

  module ExpressionParser
    include Parsby::Combinators
    extend self

    def parse(io)
      expression.parse io
    end

    define_combinator :expression do
      choice(literal, binary_expression, and_expression, or_expression) < eof
    end

    define_combinator :quote do
      lit('"')
    end

    define_combinator :open_paren do
      lit('(')
    end

    define_combinator :close_paren do
      lit(')')
    end

    define_combinator :chars do
      join(many(any_char.that_fail(quote))).fmap do |str|
        str.force_encoding('utf-8').encode
      end
    end

    define_combinator :string do
      between(quote, quote, chars).fmap do |value|
        { term: 'Logic::Constant', value: value }
      end
    end

    define_combinator :boolean do
      (lit('true') | lit('false')).fmap do |value|
        { term: 'Logic::Constant', value: value == 'true' }
      end
    end

    define_combinator :number do
      decimal.fmap do |value|
        { term: 'Logic::Constant', value: value }
      end
    end

    define_combinator :null do
      lit('null').fmap do
        { term: 'Logic::Empty' }
      end
    end

    define_combinator :identifier do
      join(many_1(char_in('a'..'z', 'A'..'Z', 0..9, '='))).fmap do |id|
        Champ.decode_typed_id(id)[0].to_i
      end
    end

    define_combinator :champ_value do
      (lit('@') > identifier).fmap do |stable_id|
        { term: 'Logic::ChampValue', stable_id: stable_id }
      end
    end

    define_combinator :operator do
      choice(lit('==').fmap { 'Logic::Eq' },
        lit('!=').fmap { 'Logic::NotEq' },
        lit('>').fmap { 'Logic::GreaterThan' },
        lit('>=').fmap { 'Logic::GreaterThanEq' },
        lit('<').fmap { 'Logic::LessThan' },
        lit('<=').fmap { 'Logic::LessThanEq' },
        lit('include?').fmap { 'Logic::IncludeOperator' },
        lit('_').fmap { 'Logic::EmptyOperator' }).fmap do |term|
          { term: term }
        end
    end

    define_combinator :literal do
      boolean | number | null | string | champ_value
    end

    define_combinator :binary_expression do
      between(open_paren, close_paren, group(literal, spaced(operator), literal)).fmap do |(left, term, right)|
        term.merge(left: left, right: right)
      end
    end

    define_combinator :and_expression do
      between(open_paren, close_paren, sep_by_1(spaced(lit('&&')), binary_expression | literal)).fmap do |operands|
        { term: 'Logic::And', operands: operands }
      end
    end

    define_combinator :or_expression do
      between(open_paren, close_paren, sep_by_1(spaced(lit('||')), binary_expression | literal)).fmap do |operands|
        { term: 'Logic::Or', operands: operands }
      end
    end
  end
end
