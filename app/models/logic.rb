module Logic
  def self.from_h(h)
    class_from_name(h['op']).from_h(h)
  end

  def self.from_json(s)
    from_h(JSON.parse(s))
  end

  def self.class_from_name(name)
    [Constant, Empty]
      .find { |c| c.name == name }
  end

  def constant(value) = Logic::Constant.new(value)

  def empty = Logic::Empty.new

end
