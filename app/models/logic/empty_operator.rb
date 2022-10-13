class Logic::EmptyOperator < Logic::BinaryOperator
  def to_s(_type_de_champs = []) = "empty operator"

  def to_expression = "(#{@left.to_expression} _ #{@right.to_expression})"

  def type(_type_de_champs = []) = :empty

  def errors(_type_de_champs = []) = []

  def compute(_champs = [])
    true
  end
end
