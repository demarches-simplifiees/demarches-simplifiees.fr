class Logic::Empty < Logic::Term
  def initialize(id = nil)
    super(id)
  end

  def to_s = I18n.t('logic.empty')

  def type = :empty

  def errors(_stable_ids = nil) = ['empty']

  def to_h
    {
      "term" => self.class.name,
      "id" => @id
    }
  end

  def self.from_h(h)
    self.new(h['id'])
  end

  def ==(other)
    self.class == other.class
  end

  def value
    nil
  end
end
