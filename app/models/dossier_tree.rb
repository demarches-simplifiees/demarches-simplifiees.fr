# frozen_string_literal: true

class DossierTree
  attr_reader :children

  def initialize(context)
    @children = context.children(nil, [])
  end

  def champs = children.flat_map(&:champs)
  def repeaters = children.flat_map(&:repeaters)
  def sections = children.flat_map(&:sections)
  def flatten = children.flat_map(&:flatten)
end
