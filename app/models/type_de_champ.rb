# == Schema Information
#
# Table name: types_de_champ
#
#  id          :integer          not null, primary key
#  condition   :jsonb
#  description :text
#  libelle     :string
#  mandatory   :boolean          default(FALSE)
#  options     :jsonb
#  private     :boolean          default(FALSE), not null
#  type_champ  :string
#  created_at  :datetime
#  updated_at  :datetime
#  stable_id   :bigint
#
class TypeDeChamp < ApplicationRecord
  self.ignored_columns = [:migrated_parent, :revision_id, :parent_id, :order_place]

  FILE_MAX_SIZE = 200.megabytes
  FEATURE_FLAGS = {}

  CADRE = :cadre
  STANDARD = :standard
  CHOICE = :choice
  ETAT_CIVIL = :etat_civil
  PAIEMENT_IDENTIFICATION = :paiement_identification
  REFERENTIEL_EXTERNE = :referentiel_externe
  LOCALISATION = :localisation

  CATEGORIES = [CADRE, ETAT_CIVIL, LOCALISATION, PAIEMENT_IDENTIFICATION, STANDARD, CHOICE, REFERENTIEL_EXTERNE]

  TYPE_DE_CHAMP_TO_CATEGORIE = {
    text: STANDARD,
    textarea: STANDARD,
    date: STANDARD,
    datetime: STANDARD,
    number: STANDARD,
    decimal_number: STANDARD,
    integer_number: STANDARD,
    checkbox: CHOICE,
    civilite: ETAT_CIVIL,
    email: ETAT_CIVIL,
    phone: ETAT_CIVIL,
    address: LOCALISATION,
    yes_no: CHOICE,
    drop_down_list: CHOICE,
    multiple_drop_down_list: CHOICE,
    linked_drop_down_list: CHOICE,
    pays: LOCALISATION,
    regions: LOCALISATION,
    departements: LOCALISATION,
    communes: LOCALISATION,
    header_section: CADRE,
    explication: CADRE,
    dossier_link: CADRE,
    piece_justificative: STANDARD,
    rna: REFERENTIEL_EXTERNE,
    siret: PAIEMENT_IDENTIFICATION,
    carte: REFERENTIEL_EXTERNE,
    repetition: CADRE,
    titre_identite: ETAT_CIVIL,
    iban: PAIEMENT_IDENTIFICATION,
    annuaire_education: REFERENTIEL_EXTERNE,
    cnaf: REFERENTIEL_EXTERNE,
    dgfip: REFERENTIEL_EXTERNE,
    pole_emploi: REFERENTIEL_EXTERNE,
    mesri: REFERENTIEL_EXTERNE
  }

  enum type_champs: {
    text: 'text',
    textarea: 'textarea',
    date: 'date',
    datetime: 'datetime',
    number: 'number',
    decimal_number: 'decimal_number',
    integer_number: 'integer_number',
    checkbox: 'checkbox',
    civilite: 'civilite',
    email: 'email',
    phone: 'phone',
    address: 'address',
    yes_no: 'yes_no',
    drop_down_list: 'drop_down_list',
    multiple_drop_down_list: 'multiple_drop_down_list',
    linked_drop_down_list: 'linked_drop_down_list',
    communes: 'communes',
    departements: 'departements',
    regions: 'regions',
    pays: 'pays',
    header_section: 'header_section',
    explication: 'explication',
    dossier_link: 'dossier_link',
    piece_justificative: 'piece_justificative',
    rna: 'rna',
    carte: 'carte',
    repetition: 'repetition',
    titre_identite: 'titre_identite',
    iban: 'iban',
    siret: 'siret',
    annuaire_education: 'annuaire_education',
    cnaf: 'cnaf',
    dgfip: 'dgfip',
    pole_emploi: 'pole_emploi',
    mesri: 'mesri'
  }

  store_accessor :options,
                 :cadastres,
                 :old_pj,
                 :drop_down_options,
                 :skip_pj_validation,
                 :skip_content_type_pj_validation,
                 :drop_down_secondary_libelle,
                 :drop_down_secondary_description,
                 :drop_down_other,
                 :collapsible_explanation_enabled,
                 :collapsible_explanation_text

  has_many :revision_types_de_champ, -> { revision_ordered }, class_name: 'ProcedureRevisionTypeDeChamp', dependent: :destroy, inverse_of: :type_de_champ
  has_one :revision_type_de_champ, -> { revision_ordered }, class_name: 'ProcedureRevisionTypeDeChamp', inverse_of: false
  has_many :revisions, -> { ordered }, through: :revision_types_de_champ
  has_one :revision, through: :revision_type_de_champ
  has_one :procedure, through: :revision

  delegate :estimated_fill_duration, :estimated_read_duration, :tags_for_template, :libelle_for_export, to: :dynamic_type

  class WithIndifferentAccess
    def self.load(options)
      options&.with_indifferent_access
    end

    def self.dump(options)
      options
    end
  end

  serialize :options, WithIndifferentAccess

  class ConditionSerializer
    def self.load(condition)
      if condition.present?
        Logic.from_h(condition)
      end
    end

    def self.dump(condition)
      if condition.present?
        condition.to_h
      end
    end
  end

  serialize :condition, ConditionSerializer

  after_initialize :set_dynamic_type
  after_create :populate_stable_id

  attr_reader :dynamic_type

  scope :public_only, -> { where(private: false) }
  scope :private_only, -> { where(private: true) }
  scope :repetition, -> { where(type_champ: type_champs.fetch(:repetition)) }
  scope :not_repetition, -> { where.not(type_champ: type_champs.fetch(:repetition)) }
  scope :fillable, -> { where.not(type_champ: [type_champs.fetch(:header_section), type_champs.fetch(:explication)]) }

  scope :dubious, -> {
    where("unaccent(types_de_champ.libelle) ~* unaccent(?)", DubiousProcedure.forbidden_regexp)
      .where(type_champ: [TypeDeChamp.type_champs.fetch(:text), TypeDeChamp.type_champs.fetch(:textarea)])
  }

  has_many :champ, inverse_of: :type_de_champ, dependent: :destroy do
    def build(params = {})
      params.delete(:revision)
      super(params.merge(proxy_association.owner.params_for_champ))
    end

    def create(params = {})
      params.delete(:revision)
      super(params.merge(proxy_association.owner.params_for_champ))
    end
  end

  has_one_attached :piece_justificative_template
  validates :piece_justificative_template, size: { less_than: FILE_MAX_SIZE }
  validates :piece_justificative_template, content_type: AUTHORIZED_CONTENT_TYPES

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :type_champ, presence: true, allow_blank: false, allow_nil: false

  before_validation :check_mandatory
  before_save :remove_piece_justificative_template, if: -> { type_champ_changed? }
  before_validation :remove_drop_down_list, if: -> { type_champ_changed? }
  before_save :remove_block, if: -> { type_champ_changed? }

  after_save if: -> { @remove_piece_justificative_template } do
    piece_justificative_template.purge_later
  end

  def valid?(context = nil)
    super
    if dynamic_type.present?
      dynamic_type.valid?
      errors.merge!(dynamic_type.errors)
    end
    errors.empty?
  end

  alias_method :validate, :valid?

  def set_dynamic_type
    @dynamic_type = type_champ.present? ? self.class.type_champ_to_class_name(type_champ).constantize.new(self) : nil
  end

  def type_champ=(value)
    super(value)
    set_dynamic_type
  end

  def params_for_champ
    {
      private: private?,
      type: "Champs::#{type_champ.classify}Champ"
    }
  end

  def build_champ(params)
    dynamic_type.build_champ(params)
  end

  def check_mandatory
    if non_fillable?
      self.mandatory = false
    else
      true
    end
  end

  def only_present_on_draft?
    revisions.size == 1
  end

  def drop_down_other?
    drop_down_other == "1" || drop_down_other == true
  end

  def collapsible_explanation_enabled?
    collapsible_explanation_enabled == "1"
  end

  def fillable?
    !non_fillable?
  end

  def non_fillable?
    type_champ.in?([
      TypeDeChamp.type_champs.fetch(:header_section),
      TypeDeChamp.type_champs.fetch(:explication)
    ])
  end

  def exclude_from_export?
    type_champ.in?([
      TypeDeChamp.type_champs.fetch(:header_section),
      TypeDeChamp.type_champs.fetch(:explication),
      TypeDeChamp.type_champs.fetch(:repetition)
    ])
  end

  def drop_down_list?
    type_champ.in?([
      TypeDeChamp.type_champs.fetch(:drop_down_list),
      TypeDeChamp.type_champs.fetch(:multiple_drop_down_list),
      TypeDeChamp.type_champs.fetch(:linked_drop_down_list)
    ])
  end

  def simple_drop_down_list?
    type_champ == TypeDeChamp.type_champs.fetch(:drop_down_list)
  end

  def linked_drop_down_list?
    type_champ == TypeDeChamp.type_champs.fetch(:linked_drop_down_list)
  end

  def block?
    type_champ == TypeDeChamp.type_champs.fetch(:repetition)
  end

  def header_section?
    type_champ == TypeDeChamp.type_champs.fetch(:header_section)
  end

  def exclude_from_view?
    type_champ == TypeDeChamp.type_champs.fetch(:explication)
  end

  def explication?
    type_champ == TypeDeChamp.type_champs.fetch(:explication)
  end

  def repetition?
    type_champ == TypeDeChamp.type_champs.fetch(:repetition)
  end

  def dossier_link?
    type_champ == TypeDeChamp.type_champs.fetch(:dossier_link)
  end

  def siret?
    type_champ == TypeDeChamp.type_champs.fetch(:siret)
  end

  def piece_justificative?
    type_champ == TypeDeChamp.type_champs.fetch(:piece_justificative) || type_champ == TypeDeChamp.type_champs.fetch(:titre_identite)
  end

  def legacy_number?
    type_champ == TypeDeChamp.type_champs.fetch(:number)
  end

  def titre_identite?
    type_champ == TypeDeChamp.type_champs.fetch(:titre_identite)
  end

  def carte?
    type_champ == TypeDeChamp.type_champs.fetch(:carte)
  end

  def cnaf?
    type_champ == TypeDeChamp.type_champs.fetch(:cnaf)
  end

  def rna?
    type_champ == TypeDeChamp.type_champs.fetch(:rna)
  end

  def dgfip?
    type_champ == TypeDeChamp.type_champs.fetch(:dgfip)
  end

  def pole_emploi?
    type_champ == TypeDeChamp.type_champs.fetch(:pole_emploi)
  end

  def mesri?
    type_champ == TypeDeChamp.type_champs.fetch(:mesri)
  end

  def public?
    !private?
  end

  def self.type_champ_to_class_name(type_champ)
    "TypesDeChamp::#{type_champ.classify}TypeDeChamp"
  end

  def piece_justificative_template_filename
    if piece_justificative_template.attached?
      piece_justificative_template.filename
    end
  end

  def piece_justificative_template_checksum
    if piece_justificative_template.attached?
      piece_justificative_template.checksum
    end
  end

  def drop_down_list_value
    if drop_down_list_options.present?
      drop_down_list_options.reject(&:empty?).join("\r\n")
    else
      ''
    end
  end

  def drop_down_list_value=(value)
    self.drop_down_options = parse_drop_down_list_value(value)
  end

  # historicaly we added a blank ("") option by default to avoid wrong selection
  #   see self.parse_drop_down_list_value
  #   then rails decided to add this blank ("") option when the select is required
  #   so we revert this change
  def options_without_empty_value_when_mandatory(options)
    mandatory? ? options.reject(&:blank?) : options
  end

  def drop_down_list_options?
    drop_down_list_options.any?
  end

  def drop_down_list_options
    drop_down_options.presence || []
  end

  def drop_down_list_disabled_options
    drop_down_list_options.filter { |v| (v =~ /^--.*--$/).present? }
  end

  def drop_down_list_enabled_non_empty_options
    (drop_down_list_options - drop_down_list_disabled_options).reject(&:empty?)
  end

  def layer_enabled?(layer)
    options && options[layer] && options[layer] != '0'
  end

  def carte_optional_layers
    TypesDeChamp::CarteTypeDeChamp::LAYERS.filter_map do |layer|
      layer_enabled?(layer) ? layer : nil
    end.sort
  end

  def to_typed_id
    GraphQL::Schema::UniqueWithinType.encode('Champ', stable_id)
  end

  def editable_options=(options)
    self.options.merge!(options)
  end

  def editable_options
    layers = TypesDeChamp::CarteTypeDeChamp::LAYERS.map do |layer|
      [layer, layer_enabled?(layer)]
    end
    layers.each_slice((layers.size / 2.0).round).to_a
  end

  def read_attribute_for_serialization(name)
    if name == 'id'
      stable_id
    else
      super
    end
  end

  def destroy_if_orphan
    if revision_types_de_champ.empty?
      destroy
    end
  end

  def stable_self
    OpenStruct.new(to_key: [stable_id],
      model_name: OpenStruct.new(param_key: model_name.param_key))
  end

  private

  DEFAULT_EMPTY = ['']
  def parse_drop_down_list_value(value)
    value = value ? value.split("\r\n").map(&:strip).join("\r\n") : ''
    result = value.split(/[\r\n]|[\r]|[\n]|[\n\r]/).reject(&:empty?)
    result.blank? ? [] : DEFAULT_EMPTY + result
  end

  def populate_stable_id
    if !stable_id
      update_column(:stable_id, id)
    end
  end

  def remove_piece_justificative_template
    if !piece_justificative? && piece_justificative_template.attached?
      @remove_piece_justificative_template = true
    end
  end

  def remove_drop_down_list
    if !drop_down_list?
      self.drop_down_options = nil
    elsif !drop_down_options_changed?
      self.drop_down_options = if linked_drop_down_list?
        ['', '--Fromage--', 'bleu de sassenage', 'picodon', '--Dessert--', 'éclair', 'tarte aux pommes']
      else
        ['', 'Premier choix', 'Deuxième choix']
      end
    end
  end

  def remove_block
    if !block? && procedure.present?
      procedure
        .draft_revision # action occurs only on draft
        .remove_children_of(self)
    end
  end
end
