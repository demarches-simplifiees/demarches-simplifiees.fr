# frozen_string_literal: true

class DossierTree::Repeater
  attr_reader :id, :rows, :ancestors, :html_id

  def initialize(type_de_champ, context, ancestors:)
    @id = context.public_id(type_de_champ)
    @html_id = context.html_id(type_de_champ)
    @type_de_champ = type_de_champ
    @ancestors = ancestors
    @visible = context.visible?(type_de_champ, ancestors)
    @rows = context.row_ids(type_de_champ)
      .map { Row.new(self, _1, type_de_champ, context, ancestors:) }
    @visible = false if visible? && rows.none?(&:visible?)
  end

  def section? = false
  def champ? = false
  def repeater? = true
  def explication? = false

  DossierTree::Champ::TYPE_PREDICATES.each do |predicate|
    define_method(predicate) { false }
  end

  def libelle = @type_de_champ.libelle
  def description = @type_de_champ.description
  def required? = @type_de_champ.mandatory? && visible?
  def visible? = @visible

  def to_key = [id]
  def model_name = @_model_name ||= ActiveModel::Name.new(self, nil, 'repeater')

  def depth = ancestors.size
  def parent = ancestors.last
  def row? = false

  def champs = rows.flat_map(&:champs)
  def repeaters = [self]
  def sections = rows.flat_map(&:sections)
  def flatten = [self] + rows.flat_map(&:flatten)

  class Row
    attr_reader :id, :children, :repeater

    def initialize(repeater, id, type_de_champ, context, ancestors:)
      @id = id
      context = context.with_row(self)
      @key = context.public_id(type_de_champ)
      @repeater = repeater
      @visible = repeater.visible?
      @children = context.children(type_de_champ.stable_id, ancestors + [self])
      @visible = false if visible? && children.none?(&:visible?)
    end

    def visible? = @visible

    def champs = children.flat_map(&:champs)
    def sections = children.flat_map(&:sections)
    def flatten = children.flat_map(&:flatten)

    def to_key = [@key]
    def model_name = @_model_name ||= ActiveModel::Name.new(self, nil, 'repeater_row')
  end
end
