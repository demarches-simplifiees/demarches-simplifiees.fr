class Logic::Constant < Logic::Term
  attr_reader :value

  def initialize(value, id = nil)
    @value = value
    super(id)
  end

  def compute(_champs = nil) = @value

  def to_s
    case @value
    when TrueClass
      I18n.t('utils.yes')
    when FalseClass
      I18n.t('utils.no')
    else
      @value.to_s
    end
  end

  def type
    case @value
    when TrueClass, FalseClass
      :boolean
    when Integer, Float
      :number
    else
      @value.class.name.downcase.to_sym
    end
  end

  def errors(_stable_ids = nil) = []

  def to_h
    {
      "term" => self.class.name,
      "value" => @value,
      "id" => @id
    }
  end

  def self.from_h(h)
    self.new(h['value'], h['id'])
  end

  def ==(other)
    self.class == other.class && @value == other.value
  end
end
