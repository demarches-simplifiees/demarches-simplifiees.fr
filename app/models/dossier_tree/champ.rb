# frozen_string_literal: true

class DossierTree::Champ
  include ActiveModel::Validations

  attr_reader :id, :ancestors, :columns

  def initialize(type_de_champ, context, ancestors:)
    @id = context.public_id(type_de_champ)
    @type_de_champ = type_de_champ
    @ancestors = ancestors
    @columns = context.columns(type_de_champ)
    @data = context.data(type_de_champ)
    @visible = context.visible?(type_de_champ, ancestors, blank: value_blank?)

    if @data
      context.seen(@data) if @visible

      # FIXME we need this for compatibility with old champs
      @data.set_visibility(@visible)
    end
  end

  validate :validate_required, on: :submit, if: :required?

  def section? = false
  def champ? = true
  def repeater? = false
  def explication? = false

  def type = @type_de_champ.type_champ
  def libelle = @type_de_champ.libelle
  def description = @type_de_champ.description
  def required? = @type_de_champ.mandatory? && visible?
  def value = @data ? columns.first&.value(@data) : nil
  def to_s = blank? ? "" : value.to_s
  def visible? = @visible
  def blank? = visible? ? value_blank? : true
  def created_at = @data&.created_at
  def updated_at = @data&.updated_at
  def depose_at = @data&.dossier&.depose_at
  def private? = @type_de_champ.private?
  def public? = !private?
  def stable_id = @type_de_champ.stable_id

  def to_key = [id]
  def model_name = @_model_name ||= ActiveModel::Name.new(self, nil, 'champ')

  def depth = ancestors.size
  def parent = ancestors.last
  def row = ancestors.find { _1.class == DossierTree::Repeater::Row }
  def row? = row.present?
  def repeater = row&.repeater

  def champs = [self]
  def repeaters = []
  def sections = []
  def flatten = [self]

  NON_CHAMP_TYPES = ['repetition', 'header_section', 'explication']
  COMBINED_TYPES = ['piece_justificative_or_titre_identite', 'any_drop_down_list']
  TYPE_PREDICATES = (TypeDeChamp.type_champs.values.reject { _1.in?(NON_CHAMP_TYPES) } + COMBINED_TYPES).map { "#{_1}?".to_sym }
  delegate(*TYPE_PREDICATES, to: :@type_de_champ)

  def self.build(type_de_champ, context, ancestors:)
    "DossierTree::Champs::#{type_de_champ.type_champ.classify}Champ".constantize.new(type_de_champ, context, ancestors:)
  end

  private

  def value_blank?
    value != false && value.blank?
  end

  def validate_required
    errors.add(:value, :blank) if value != false && value.blank?
  end
end
