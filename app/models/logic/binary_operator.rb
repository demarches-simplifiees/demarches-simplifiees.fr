class Logic::BinaryOperator < Logic::Term
  attr_reader :left, :right

  def initialize(left, right, id = nil)
    @left, @right = left, right
    super(id)
  end

  def to_h
    {
      "term" => self.class.name,
      "left" => @left.to_h,
      "right" => @right.to_h,
      "id" => @id
    }
  end

  def self.from_h(h)
    self.new(Logic.from_h(h['left']), Logic.from_h(h['right']), h['id'])
  end

  def errors(stable_ids = [])
    errors = []

    if @left.type != :number || @right.type != :number
      errors += ["les types sont incompatibles : #{self}"]
    end

    errors + @left.errors(stable_ids) + @right.errors(stable_ids)
  end

  def type = :boolean

  def compute(champs = [])
    l = @left.compute(champs)
    r = @right.compute(champs)

    l.send(operation, r)
  end

  def to_s = "(#{@left} #{operation} #{@right})"

  def ==(other)
    self.class == other.class &&
      @left == other.left &&
      @right == other.right
  end
end
