# frozen_string_literal: true

class Logic::Group < Logic::Term
  attr_reader :content

  def initialize(content)
    @content = content
  end

  def compute(champs = [])
    content.compute(champs)
  end

  def to_s(type_de_champs) = content.to_s(type_de_champs)

  def to_h
    {
      "term" => self.class.name,
      "content" => @content.to_h
    }
  end

  def self.from_h(h)
    self.new(Logic.from_h(h['content']))
  end

  def errors(type_de_champs = [])
  end
end
