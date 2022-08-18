class Logic::Empty < Logic::Term
  def to_s = "empty member"

  def type = :empty

  def errors(_stable_ids = nil) = ['empty']

  def to_h
    {
      "op" => self.class.name
    }
  end

  def self.from_h(_h)
    self.new
  end

  def ==(other)
    self.class == other.class
  end
end
