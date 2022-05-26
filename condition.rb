require 'byebug'

class Champ
  attr_accessor :id, :value

  def initialize(id, value)
    self.id = id
    self.value = value
  end
end

class Term
  def initialize(operand_1 = nil, operand_2 = nil)
    @operand_1 = operand_1
    @operand_2 = operand_2
  end

  def self.from_h(h)
    (IntermediaryTerm.subclasses + LeafTerm.subclasses)
      .find { |c| c.name == h["op"] }
      .from_h(h)
  end
end

class LeafTerm < Term
  def to_h
    {
      "op" => self.class.name,
      "operand_1" => @operand_1
    }
  end

  def self.from_h(h)
    self.new(h['operand_1'])
  end
end

class IntermediaryTerm < Term
  def to_h
    { 
      "op" => self.class.name, 
      "operand_1" => @operand_1.to_h, 
      "operand_2" => @operand_2.to_h 
    }
  end

  def self.from_h(h)
    self.new(Term.from_h(h['operand_1']), Term.from_h(h['operand_2']))
  end
end

class ChampValue < LeafTerm
  def apply(champs)
    champs.find { |c| c.id == @operand_1 }.value
  end
end

class Constant < LeafTerm
  def apply(_champs) = @operand_1
end

class Eq < IntermediaryTerm
  def apply(champs)
    @operand_1.apply(champs) == @operand_2.apply(champs)
  end
end

class Or < IntermediaryTerm
  def apply(champs)
    @operand_1.apply(champs) || @operand_2.apply(champs)
  end
end

class And < IntermediaryTerm
  def apply(champs)
    @operand_1.apply(champs) && @operand_2.apply(champs)
  end
end

c1 = Champ.new(1, 1) ; c2 = Champ.new(2, 2) ; c3 = Champ.new(3, 1)
champs = [c1, c2, c3]

predicat_1 = Eq.new(ChampValue.new(c1.id), ChampValue.new(c3.id))
puts Term.from_h(predicat_1.to_h).apply(champs)

predicat_2 = Eq.new(ChampValue.new(c1.id), ChampValue.new(c2.id))
puts Term.from_h(predicat_2.to_h).apply(champs)

predicat_3 = Or.new(predicat_1, predicat_2)
puts Term.from_h(predicat_3.to_h).apply(champs)

predicat_4 = Eq.new(ChampValue.new(c1.id), Constant.new(1))
puts Term.from_h(predicat_4.to_h).apply(champs)

puts Eq.new(Eq.new(Constant.new(1), Constant.new(1)), Eq.new(Constant.new(2), Constant.new(1))).apply(champs)
