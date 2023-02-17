class Logic::EmptyOperator < Logic::BinaryOperator
  def to_s(_type_de_champs = []) = "empty operator"

  def type(_type_de_champs = []) = :empty

  def errors(_type_de_champs = []) = []

  def compute(_champs = [])
    true
  end
end
