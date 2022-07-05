class Logic::NAryOperator < Logic::Term
  attr_reader :operands

  def initialize(operands, id = nil)
    @operands = operands
    super(id)
  end

  def to_h
    {
      "term" => self.class.name,
      "operands" => @operands.map(&:to_h),
      "id" => @id
    }
  end

  def self.from_h(h)
    self.new(h['operands'].map { |operand_h| Logic.from_h(operand_h) }, h['id'])
  end

  def errors(stable_ids = [])
    errors = []

    if @operands.empty?
      errors += ["opérateur '#{operator_name}' vide"]
    end

    not_booleans = @operands.filter { |operand| operand.type != :boolean }
    if not_booleans.present?
      errors += ["'#{operator_name}' ne contient pas que des booléens : #{not_booleans.map(&:to_s).join(', ')}"]
    end

    errors + @operands.flat_map { |operand| operand.errors(stable_ids) }
  end

  def type = :boolean

  def ==(other)
    self.class == other.class &&
      @operands.count == other.operands.count &&
      @operands.all? do |operand|
        @operands.count { |o| o == operand } == other.operands.count { |o| o == operand }
      end
  end
end
