class Logic::Empty < Logic::Term
  def to_s = I18n.t('logic.empty')

  def type(_type_de_champs = []) = :empty

  def errors(_stable_ids = nil) = ['empty']

  def to_h
    {
      "term" => self.class.name
    }
  end

  def self.from_h(_h)
    self.new
  end

  def ==(other)
    self.class == other.class
  end

  def value
    nil
  end
end
