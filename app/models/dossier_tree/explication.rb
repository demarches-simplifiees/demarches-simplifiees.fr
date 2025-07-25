# frozen_string_literal: true

class DossierTree::Explication
  attr_reader :id, :ancestors

  def initialize(type_de_champ, context, ancestors:)
    @id = context.public_id(type_de_champ)
    @type_de_champ = type_de_champ
    @ancestors = ancestors
    @visible = context.visible?(@type_de_champ, ancestors)
  end

  def section? = false
  def champ? = false
  def repeater? = false
  def explication? = true

  DossierTree::Champ::TYPE_PREDICATES.each do |predicate|
    define_method(predicate) { false }
  end

  def libelle = @type_de_champ.libelle
  def description = @type_de_champ.description
  def visible? = @visible

  def to_key = [id]
  def model_name = @_model_name ||= ActiveModel::Name.new(self, nil, 'explication')

  def depth = ancestors.size
  def parent = ancestors.last
  def row = ancestors.find { _1.class == DossierTree::Repeater::Row }
  def row? = row.present?
  def repeater = row&.repeater

  def champs = []
  def repeaters = []
  def sections = []
  def flatten = [self]
end
