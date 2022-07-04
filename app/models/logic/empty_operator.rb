class Logic::EmptyOperator < Logic::BinaryOperator
  def to_s = "empty operator"

  def type = :empty

  def errors(_stable_ids = nil) = []

  def compute(_champs = [])
    true
  end
end
