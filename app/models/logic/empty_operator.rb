class Logic::EmptyOperator < Logic::BinaryOperator
  def to_s = "empty operator"

  def type(_type_de_champs = []) = :empty

  def errors(_stable_ids = nil) = []

  def compute(_champs = [])
    true
  end
end
