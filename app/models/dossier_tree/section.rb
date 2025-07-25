# frozen_string_literal: true

class DossierTree::Section
  attr_reader :id, :children, :ancestors

  def initialize(type_de_champ, context, ancestors:)
    @id = context.public_id(type_de_champ)
    @type_de_champ = type_de_champ
    @ancestors = ancestors
    @visible = context.visible?(type_de_champ, ancestors)
    @children = context.children(type_de_champ.stable_id, ancestors + [self])
    @visible = false if visible? && children.none?(&:visible?)
  end

  def section? = true
  def champ? = false
  def repeater? = false
  def explication? = false

  DossierTree::Champ::TYPE_PREDICATES.each do |predicate|
    define_method(predicate) { false }
  end

  def libelle = @type_de_champ.libelle
  def description = @type_de_champ.description
  def visible? = @visible

  def to_key = [id]
  def model_name = @_model_name ||= ActiveModel::Name.new(self, nil, 'section')

  def depth = ancestors.size
  def level = row ? (depth - repeater.depth) : depth + 1
  def parent = ancestors.last
  def row = ancestors.find { _1.class == DossierTree::Repeater::Row }
  def row? = row.present?
  def repeater = row&.repeater

  def champs = children.flat_map(&:champs)
  def repeaters = children.flat_map(&:repeaters)
  def sections = [self] + children.flat_map(&:sections)
  def flatten = [self] + children.flat_map(&:flatten)
end
