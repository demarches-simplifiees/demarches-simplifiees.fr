class Logic::Term
  attr_reader :id

  def initialize(id = nil)
    @id = id || SecureRandom.uuid
  end

  def to_json
    to_h.to_json
  end
end
