# frozen_string_literal: true

class TypeDeChamp < ApplicationRecord
  FILE_MAX_SIZE = 200.megabytes
  FEATURE_FLAGS = {
    referentiel: :referentiel_type_de_champ,
    engagement_juridique: :engagement_juridique_type_de_champ,
    cojo: :cojo_type_de_champ
  }

  MINIMUM_TEXTAREA_CHARACTER_LIMIT_LENGTH = 400

  STRUCTURE = :structure
  ETAT_CIVIL = :etat_civil
  LOCALISATION = :localisation
  PAIEMENT_IDENTIFICATION = :paiement_identification
  STANDARD = :standard
  PIECES_JOINTES = :pieces_jointes
  CHOICE = :choice
  REFERENTIEL_EXTERNE = :referentiel_externe

  CATEGORIES = [STRUCTURE, ETAT_CIVIL, LOCALISATION, PAIEMENT_IDENTIFICATION, STANDARD, PIECES_JOINTES, CHOICE, REFERENTIEL_EXTERNE]

  TYPE_DE_CHAMP_TO_CATEGORIE = {
    referentiel: REFERENTIEL_EXTERNE,
    engagement_juridique: REFERENTIEL_EXTERNE,
    header_section: STRUCTURE,
    repetition: STRUCTURE,
    dossier_link: STRUCTURE,
    explication: STRUCTURE,
    civilite: ETAT_CIVIL,
    email: ETAT_CIVIL,
    phone: ETAT_CIVIL,
    address: LOCALISATION,
    communes: LOCALISATION,
    departements: LOCALISATION,
    regions: LOCALISATION,
    pays: LOCALISATION,
    epci: LOCALISATION,
    iban: PAIEMENT_IDENTIFICATION,
    siret: PAIEMENT_IDENTIFICATION,
    text: STANDARD,
    textarea: STANDARD,
    number: STANDARD,
    decimal_number: STANDARD,
    integer_number: STANDARD,
    formatted: STANDARD,
    date: STANDARD,
    datetime: STANDARD,
    piece_justificative: PIECES_JOINTES,
    titre_identite: PIECES_JOINTES,
    checkbox: CHOICE,
    drop_down_list: CHOICE,
    multiple_drop_down_list: CHOICE,
    linked_drop_down_list: CHOICE,
    yes_no: CHOICE,
    annuaire_education: REFERENTIEL_EXTERNE,
    rna: REFERENTIEL_EXTERNE,
    rnf: REFERENTIEL_EXTERNE,
    carte: REFERENTIEL_EXTERNE,
    cnaf: REFERENTIEL_EXTERNE,
    dgfip: REFERENTIEL_EXTERNE,
    pole_emploi: REFERENTIEL_EXTERNE,
    mesri: REFERENTIEL_EXTERNE,
    cojo: REFERENTIEL_EXTERNE
  }

  enum :type_champ, {
    engagement_juridique: 'engagement_juridique',
    header_section: 'header_section',
    repetition: 'repetition',
    dossier_link: 'dossier_link',
    explication: 'explication',
    civilite: 'civilite',
    email: 'email',
    phone: 'phone',
    address: 'address',
    communes: 'communes',
    departements: 'departements',
    regions: 'regions',
    pays: 'pays',
    iban: 'iban',
    siret: 'siret',
    text: 'text',
    textarea: 'textarea',
    number: 'number',
    decimal_number: 'decimal_number',
    integer_number: 'integer_number',
    formatted: 'formatted',
    date: 'date',
    datetime: 'datetime',
    piece_justificative: 'piece_justificative',
    titre_identite: 'titre_identite',
    checkbox: 'checkbox',
    drop_down_list: 'drop_down_list',
    multiple_drop_down_list: 'multiple_drop_down_list',
    linked_drop_down_list: 'linked_drop_down_list',
    yes_no: 'yes_no',
    annuaire_education: 'annuaire_education',
    rna: 'rna',
    rnf: 'rnf',
    carte: 'carte',
    cnaf: 'cnaf',
    dgfip: 'dgfip',
    pole_emploi: 'pole_emploi',
    mesri: 'mesri',
    epci: 'epci',
    cojo: 'cojo',
    referentiel: 'referentiel'
  }

  SIMPLE_ROUTABLE_TYPES = [
    type_champs.fetch(:drop_down_list),
    type_champs.fetch(:communes),
    type_champs.fetch(:departements),
    type_champs.fetch(:regions),
    type_champs.fetch(:pays),
    type_champs.fetch(:epci),
    type_champs.fetch(:address)
  ]

  PRIVATE_ONLY_TYPES = [
    type_champs.fetch(:engagement_juridique)
  ]

  store_accessor :options,
                 :cadastres,
                 :old_pj,
                 :drop_down_options,
                 :drop_down_mode,
                 :skip_pj_validation,
                 :skip_content_type_pj_validation,
                 :drop_down_secondary_libelle,
                 :drop_down_secondary_description,
                 :drop_down_other,
                 :positive_number,
                 :min_number,
                 :max_number,
                 :range_number,
                 :date_in_past,
                 :range_date,
                 :start_date,
                 :end_date,
                 :character_limit,
                 :formatted_mode,
                 :numbers_accepted,
                 :letters_accepted,
                 :special_characters_accepted,
                 :min_character_length,
                 :max_character_length,
                 :expression_reguliere,
                 :expression_reguliere_indications,
                 :expression_reguliere_exemple_text,
                 :expression_reguliere_error_message,
                 :collapsible_explanation_enabled,
                 :collapsible_explanation_text,
                 :header_section_level,
                 :referentiel_mapping

  has_many :revision_types_de_champ, -> { revision_ordered }, class_name: 'ProcedureRevisionTypeDeChamp', dependent: :destroy, inverse_of: :type_de_champ

  has_many :revisions, -> { ordered }, through: :revision_types_de_champ

  belongs_to :referentiel, optional: true, inverse_of: :types_de_champ

  delegate :estimated_fill_duration, :estimated_read_duration, :tags_for_template, :libelles_for_export, :libelle_for_export, :primary_options, :secondary_options, :columns, to: :dynamic_type

  class WithIndifferentAccess
    def self.load(options)
      options&.with_indifferent_access
    end

    def self.dump(options)
      options
    end
  end

  serialize :options, coder: WithIndifferentAccess

  serialize :condition, coder: LogicSerializer

  attr_reader :dynamic_type

  scope :public_only, -> { where(private: false) }
  scope :private_only, -> { where(private: true) }
  scope :repetition, -> { where(type_champ: type_champs.fetch(:repetition)) }
  scope :not_repetition, -> { where.not(type_champ: type_champs.fetch(:repetition)) }
  scope :not_condition, -> { where(condition: nil) }
  scope :fillable, -> { where.not(type_champ: [type_champs.fetch(:header_section), type_champs.fetch(:explication)]) }
  scope :with_header_section, -> { where.not(type_champ: TypeDeChamp.type_champs[:explication]) }
  scope :mandatory, -> { where(mandatory: true) }

  scope :dubious, -> {
    where("unaccent(types_de_champ.libelle) ~* unaccent(?)", DubiousProcedure.forbidden_regexp)
      .where(type_champ: [TypeDeChamp.type_champs.fetch(:text), TypeDeChamp.type_champs.fetch(:textarea)])
  }

  has_one_attached :piece_justificative_template
  validates :piece_justificative_template, size: { less_than: FILE_MAX_SIZE }, on: :update
  validates :piece_justificative_template, content_type: AUTHORIZED_CONTENT_TYPES, on: :update

  has_one_attached :notice_explicative
  validates :notice_explicative, content_type: [
    "application/msword",
    "application/pdf",
    "application/vnd.ms-powerpoint",
    "application/vnd.oasis.opendocument.presentation",
    "application/vnd.oasis.opendocument.text",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "image/jpeg",
    "image/jpg",
    "image/png",
    "text/plain"
  ], size: { less_than: 20.megabytes }, on: :update

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :type_champ, presence: true, allow_blank: false, allow_nil: false
  validates :character_limit, numericality: {
    greater_than_or_equal_to: MINIMUM_TEXTAREA_CHARACTER_LIMIT_LENGTH,
    only_integer: true,
    allow_blank: true
  }

  after_initialize :set_dynamic_type
  after_create :populate_stable_id

  before_validation :check_mandatory
  before_validation :set_default_libelle, if: -> { type_champ_changed? }
  before_validation :normalize_libelle
  before_validation :set_drop_down_list_options, if: -> { type_champ_changed? }

  before_save :remove_attachment, if: -> { type_champ_changed? }

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

  def set_default_libelle
    libelle_was_default = libelle == default_libelle(type_champ_was)
    self.libelle = default_libelle(type_champ) if libelle.blank? || libelle_was_default
  end

  def default_libelle(type_champ)
    return if type_champ.blank?

    I18n.t(type_champ,
      scope: [:activerecord, :attributes, :type_de_champ, :default_libelle],
      default: I18n.t(type_champ, scope: [:activerecord, :attributes, :type_de_champ, :type_champs]))
  end

  def params_for_champ
    {
      private: private?,
      type: champ_class.name,
      stable_id:,
      stream: Champ::MAIN_STREAM
    }
  end

  def champ_class
    self.class.type_champ_to_champ_class_name(type_champ).constantize
  end

  def build_champ(params = {})
    champ_class.new(params_for_champ.merge(params))
  end

  def check_mandatory
    if non_fillable? || private?
      self.mandatory = false
    else
      true
    end
  end

  def only_present_on_draft?
    revisions.one? && revisions.first.draft?
  end

  def drop_down_other?
    drop_down_list? && (drop_down_other == "1" || drop_down_other == true)
  end

  def positive_number?
    positive_number == "1"
  end

  def range_number?
    range_number == "1"
  end

  def date_in_past?
    date_in_past == "1"
  end

  def range_date?
    range_date == "1"
  end

  def character_limit?
    character_limit.present?
  end

  def collapsible_explanation_enabled?
    collapsible_explanation_enabled == "1"
  end

  def prefillable?
    type_champ.in?([
      TypeDeChamp.type_champs.fetch(:text),
      TypeDeChamp.type_champs.fetch(:textarea),
      TypeDeChamp.type_champs.fetch(:decimal_number),
      TypeDeChamp.type_champs.fetch(:integer_number),
      TypeDeChamp.type_champs.fetch(:formatted),
      TypeDeChamp.type_champs.fetch(:email),
      TypeDeChamp.type_champs.fetch(:phone),
      TypeDeChamp.type_champs.fetch(:iban),
      TypeDeChamp.type_champs.fetch(:civilite),
      TypeDeChamp.type_champs.fetch(:pays),
      TypeDeChamp.type_champs.fetch(:regions),
      TypeDeChamp.type_champs.fetch(:departements),
      TypeDeChamp.type_champs.fetch(:communes),
      TypeDeChamp.type_champs.fetch(:address),
      TypeDeChamp.type_champs.fetch(:date),
      TypeDeChamp.type_champs.fetch(:datetime),
      TypeDeChamp.type_champs.fetch(:yes_no),
      TypeDeChamp.type_champs.fetch(:checkbox),
      TypeDeChamp.type_champs.fetch(:drop_down_list),
      TypeDeChamp.type_champs.fetch(:repetition),
      TypeDeChamp.type_champs.fetch(:multiple_drop_down_list),
      TypeDeChamp.type_champs.fetch(:epci),
      TypeDeChamp.type_champs.fetch(:dossier_link),
      TypeDeChamp.type_champs.fetch(:siret)
    ])
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

  def choice_type?
    type_champ.in?([
      TypeDeChamp.type_champs.fetch(:checkbox),
      TypeDeChamp.type_champs.fetch(:drop_down_list),
      TypeDeChamp.type_champs.fetch(:multiple_drop_down_list),
      TypeDeChamp.type_champs.fetch(:yes_no)
    ])
  end

  def exclude_from_view?
    type_champ == TypeDeChamp.type_champs.fetch(:explication)
  end

  def public?
    !private?
  end

  def child?(revision)
    revision.coordinate_for(self)&.child?
  end

  def filename_for_attachement(attachment_sym)
    attachment = send(attachment_sym)
    if attachment.attached?
      attachment.filename
    end
  end

  def checksum_for_attachment(attachment_sym)
    attachment = send(attachment_sym)
    if attachment.attached?
      attachment.checksum
    end
  end

  def formatted_simple?
    formatted? && formatted_mode != 'advanced'
  end

  def formatted_advanced?
    formatted? && formatted_mode == 'advanced'
  end

  def drop_down_simple?
    drop_down_list? && drop_down_mode != 'advanced'
  end

  def drop_down_advanced?
    drop_down_list? && drop_down_mode == 'advanced'
  end

  def drop_down_options
    if drop_down_advanced?
      Array.wrap(referentiel&.drop_down_options)
    else
      Array.wrap(super)
    end
  end

  def options_for_select
    if departements?
      APIGeoService.departement_options
    elsif regions?
      APIGeoService.region_options
    elsif any_drop_down_list?
      if drop_down_advanced?
        Array.wrap(referentiel&.options_for_select)
      else
        drop_down_options.map { [_1, _1] }
      end
    elsif yes_no?
      Champs::YesNoChamp.options
    elsif checkbox?
      Champs::CheckboxChamp.options
    end
  end

  def options_for_select_with_other
    if drop_down_other?
      options_for_select + [[I18n.t('shared.champs.drop_down_list.other'), Champs::DropDownListChamp::OTHER]]
    else
      options_for_select
    end
  end

  def drop_down_options_from_text=(text)
    self.drop_down_options = text.to_s.lines.map(&:strip).reject(&:empty?)
  end

  def header_section_level_value
    if header_section_level.presence
      header_section_level.to_i
    else
      1
    end
  end

  def previous_section_level(upper_tdcs)
    previous_header_section = upper_tdcs.reverse.find(&:header_section?)

    return 0 if !previous_header_section
    previous_header_section.header_section_level_value.to_i
  end

  def check_coherent_header_level(upper_tdcs)
    previous_level = previous_section_level(upper_tdcs)
    current_level = header_section_level_value.to_i

    difference = current_level - previous_level
    if current_level > previous_level && difference != 1
      I18n.t('activerecord.errors.type_de_champ.attributes.header_section_level.gap_error', level: current_level - previous_level - 1)
    else
      nil
    end
  end

  def current_section_level(revision)
    tdcs = private? ? revision.types_de_champ_private.to_a : revision.types_de_champ_public.to_a

    previous_section_level(tdcs.take(tdcs.find_index(self)))
  end

  def level_for_revision(revision)
    parent_type_de_champ = revision.parent_of(self)

    if parent_type_de_champ.present?
      header_section_level_value.to_i + parent_type_de_champ.current_section_level(revision)
    elsif header_section_level_value
      header_section_level_value.to_i
    else
      0
    end
  end

  def self.column_type(type_champ)
    case type_champ
    when type_champs.fetch(:datetime)
      :datetime
    when type_champs.fetch(:date)
      :date
    when type_champs.fetch(:integer_number)
      :integer
    when type_champs.fetch(:decimal_number)
      :decimal
    when type_champs.fetch(:multiple_drop_down_list)
      :enums
    when type_champs.fetch(:drop_down_list), type_champs.fetch(:departements), type_champs.fetch(:regions)
      :enum
    when type_champs.fetch(:checkbox), type_champs.fetch(:yes_no)
      :boolean
    when type_champs.fetch(:titre_identite), type_champs.fetch(:piece_justificative)
      :attachements
    else
      :text
    end
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
    KeyableModel.new(
      to_key: [stable_id],
      model_name: KeyableModel.new(param_key: model_name.param_key)
    )
  end

  def refresh_after_update?
    self.class.refresh_after_update?(type_champ)
  end

  def self.refresh_after_update?(type_champ)
    # We should refresh all champs after update except for champs using react or custom refresh
    # logic (RNA, SIRET, etc.)
    case type_champ
    when type_champs.fetch(:carte),
      type_champs.fetch(:piece_justificative),
      type_champs.fetch(:titre_identite),
      type_champs.fetch(:rna)
      false
    else
      true
    end
  end

  def simple_routable?
    type_champ.in?(SIMPLE_ROUTABLE_TYPES) && !drop_down_advanced?
  end

  def conditionable?
    Logic::ChampValue::MANAGED_TYPE_DE_CHAMP.values.include?(type_champ) && !drop_down_advanced?
  end

  def self.humanized_conditionable_types_by_category
    Logic::ChampValue::MANAGED_TYPE_DE_CHAMP_BY_CATEGORY
      .map { |_, v| v.map { "« #{I18n.t(_1, scope: [:activerecord, :attributes, :type_de_champ, :type_champs])} »" } }
  end

  def self.humanized_simple_routable_types_by_category
    Logic::ChampValue::MANAGED_TYPE_DE_CHAMP_BY_CATEGORY
      .map { |_, v| v.filter_map { "« #{I18n.t(_1, scope: [:activerecord, :attributes, :type_de_champ, :type_champs])} »" if _1.to_s.in?(SIMPLE_ROUTABLE_TYPES) } }
      .reject(&:empty?)
  end

  def self.humanized_custom_routable_types_by_category
    Logic::ChampValue::MANAGED_TYPE_DE_CHAMP_BY_CATEGORY
      .map { |_, v| v.filter_map { "« #{I18n.t(_1, scope: [:activerecord, :attributes, :type_de_champ, :type_champs])} »" if !_1.to_s.in?(SIMPLE_ROUTABLE_TYPES) } }
      .reject(&:empty?)
  end

  def invalid_regexp?
    self.errors.delete(:expression_reguliere)
    self.errors.delete(:expression_reguliere_exemple_text)

    return false if expression_reguliere.blank?
    return false if expression_reguliere_exemple_text.blank?
    return false if expression_reguliere_exemple_text.match?(Regexp.new(expression_reguliere, timeout: ExpressionReguliereValidator::TIMEOUT))

    self.errors.add(:expression_reguliere_exemple_text, I18n.t('errors.messages.mismatch_regexp'))
    true
  rescue Regexp::TimeoutError
    self.errors.add(:expression_reguliere, I18n.t('errors.messages.evil_regexp'))
    true
  rescue RegexpError
    self.errors.add(:expression_reguliere, I18n.t('errors.messages.syntax_error_regexp'))
    true
  end

  def public_id(row_id)
    self.class.public_id(stable_id, row_id)
  end

  def libelle_as_filename
    libelle.gsub(/[[:space:]]+/, ' ')
      .truncate(30, omission: '', separator: ' ')
      .parameterize
  end

  OPTS_BY_TYPE = {
    type_champs.fetch(:header_section) => [:header_section_level],
    type_champs.fetch(:explication) => [:collapsible_explanation_enabled, :collapsible_explanation_text],
    type_champs.fetch(:textarea) => [:character_limit],
    type_champs.fetch(:integer_number) => [:positive_number, :min_number, :max_number, :range_number],
    type_champs.fetch(:decimal_number) => [:positive_number, :min_number, :max_number, :range_number],
    type_champs.fetch(:date) => [:date_in_past, :start_date, :end_date, :range_date],
    type_champs.fetch(:datetime) => [:date_in_past, :start_date, :end_date, :range_date],
    type_champs.fetch(:carte) => TypesDeChamp::CarteTypeDeChamp::LAYERS,
    type_champs.fetch(:drop_down_list) => [:drop_down_other, :drop_down_options, :drop_down_mode],
    type_champs.fetch(:multiple_drop_down_list) => [:drop_down_options],
    type_champs.fetch(:linked_drop_down_list) => [:drop_down_options, :drop_down_secondary_libelle, :drop_down_secondary_description],
    type_champs.fetch(:piece_justificative) => [:old_pj, :skip_pj_validation, :skip_content_type_pj_validation],
    type_champs.fetch(:titre_identite) => [:old_pj, :skip_pj_validation, :skip_content_type_pj_validation],
    type_champs.fetch(:formatted) => [
      :formatted_mode, :numbers_accepted, :letters_accepted, :special_characters_accepted,
      :min_character_length, :max_character_length,
      :expression_reguliere, :expression_reguliere_indications, :expression_reguliere_exemple_text, :expression_reguliere_error_message
    ]
  }

  def clean_options
    kept_keys = OPTS_BY_TYPE.fetch(type_champ.to_s) { [] }
    options.slice(*kept_keys.map(&:to_s))
  end

  def champ_value(champ)
    if champ_blank?(champ)
      dynamic_type.champ_default_value
    else
      dynamic_type.champ_value(champ)
    end
  end

  def champ_value_for_api(champ, version: 2)
    if champ_blank?(champ)
      dynamic_type.champ_default_api_value(version)
    else
      dynamic_type.champ_value_for_api(champ, version:)
    end
  end

  def champ_value_for_export(champ, path = :value)
    if champ_blank?(champ)
      dynamic_type.champ_default_export_value(path)
    else
      dynamic_type.champ_value_for_export(champ, path)
    end
  end

  def champ_value_for_tag(champ, path = :value)
    if champ_blank?(champ)
      ''
    else
      dynamic_type.champ_value_for_tag(champ, path)
    end
  end

  def champ_blank?(champ)
    # no champ
    return true if champ.nil?
    # type de champ on the revision changed
    if champ.is_type?(type_champ) || castable_on_change?(champ.last_write_type_champ, type_champ)
      dynamic_type.champ_blank?(champ)
    else
      true
    end
  end

  def mandatory_blank?(champ)
    # no champ
    return true if champ.nil?
    # type de champ on the revision changed
    if champ.is_type?(type_champ) || castable_on_change?(champ.last_write_type_champ, type_champ)
      mandatory? && dynamic_type.champ_blank_or_invalid?(champ)
    else
      true
    end
  end

  def html_id(row_id = nil)
    "champ-#{public_id(row_id)}"
  end

  class << self
    def public_id(stable_id, row_id)
      if row_id.blank? || row_id == Champ::NULL_ROW_ID
        stable_id.to_s
      else
        "#{stable_id}-#{row_id}"
      end
    end

    def type_champ_to_champ_class_name(type_champ)
      "Champs::#{type_champ.classify}Champ"
    end

    def type_champ_to_class_name(type_champ)
      "TypesDeChamp::#{type_champ.classify}TypeDeChamp"
    end
  end

  CHAMP_TYPE_TO_TYPE_CHAMP = type_champs.values.map { [type_champ_to_champ_class_name(_1), _1] }.to_h

  def piece_justificative_or_titre_identite?
    type_champ.in?([
      TypeDeChamp.type_champs.fetch(:piece_justificative),
      TypeDeChamp.type_champs.fetch(:titre_identite)
    ])
  end

  def any_drop_down_list?
    type_champ.in?([
      TypeDeChamp.type_champs.fetch(:drop_down_list),
      TypeDeChamp.type_champs.fetch(:multiple_drop_down_list),
      TypeDeChamp.type_champs.fetch(:linked_drop_down_list)
    ])
  end

  private

  def castable_on_change?(from_type, to_type)
    case [from_type, to_type]
    when ['integer_number', 'decimal_number'], # recast numbers automatically
      ['decimal_number', 'integer_number'], # may lose some data, but who cares ?
      ['text', 'textarea'], # allow short text to long text
      ['text', 'formatted'], # plain text can become formatted text
      ['formatted', 'text'], # formatted text can become plain text
      ['formatted', 'textarea'], # formatted text can become long text
      ['drop_down_list', 'multiple_drop_down_list'], # single list can become multi
      ['date', 'datetime'], # date <=> datetime
      ['datetime', 'date'] # may lose some data, but who cares ?
      true
    else
      false
    end
  end

  def populate_stable_id
    if !stable_id
      update_column(:stable_id, id)
    end
  end

  def remove_attachment
    if !piece_justificative_or_titre_identite? && piece_justificative_template.attached?
      piece_justificative_template.purge_later
    elsif !explication? && notice_explicative.attached?
      notice_explicative.purge_later
    end
  end

  def set_drop_down_list_options
    if (drop_down_list? || multiple_drop_down_list?) && drop_down_options.empty?
      self.drop_down_options = ['Fromage', 'Dessert']
    elsif linked_drop_down_list? && drop_down_options.none?(/^--.*--$/)
      self.drop_down_options = ['--Fromage--', 'bleu de sassenage', 'picodon', '--Dessert--', 'éclair', 'tarte aux pommes']
    end
  end

  def normalize_libelle
    self.libelle&.strip!
  end
end
