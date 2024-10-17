class TypeDeChamp < ApplicationRecord
  self.ignored_columns += [:migrated_parent, :revision_id, :parent_id, :order_place]

  FILE_MAX_SIZE = 200.megabytes
  FEATURE_FLAGS = {
    visa: :visa,
    referentiel_de_polynesie: :referentiel_de_polynesie,
    tefenua: :tefenua,
    engagement_juridique: :engagement_juridique_type_de_champ,
    cojo: :cojo_type_de_champ,
    expression_reguliere: :expression_reguliere_type_de_champ
  }

  MINIMUM_TEXTAREA_CHARACTER_LIMIT_LENGTH = 400

  INSTANCE_TYPE_CHAMPS = {
    nationalites: 'nationalites',
    commune_de_polynesie: 'commune_de_polynesie',
    code_postal_de_polynesie: 'code_postal_de_polynesie',
    numero_dn: 'numero_dn',
    referentiel_de_polynesie: 'referentiel_de_polynesie',
    te_fenua: 'te_fenua',
    visa: 'visa'
  }

  STRUCTURE = :structure
  ETAT_CIVIL = :etat_civil
  LOCALISATION = :localisation
  PAIEMENT_IDENTIFICATION = :paiement_identification
  STANDARD = :standard
  PIECES_JOINTES = :pieces_jointes
  CHOICE = :choice
  REFERENTIEL_EXTERNE = :referentiel_externe

  CATEGORIES = [STRUCTURE, ETAT_CIVIL, LOCALISATION, PAIEMENT_IDENTIFICATION, STANDARD, PIECES_JOINTES, CHOICE, REFERENTIEL_EXTERNE]

  INSTANCE_TYPE_DE_CHAMP_TO_CATEGORIE = {
    nationalites: ETAT_CIVIL,
    commune_de_polynesie: LOCALISATION,
    code_postal_de_polynesie: LOCALISATION,
    numero_dn: REFERENTIEL_EXTERNE,
    te_fenua: REFERENTIEL_EXTERNE,
    referentiel_de_polynesie: REFERENTIEL_EXTERNE,
    visa: STRUCTURE
  }

  TYPE_DE_CHAMP_TO_CATEGORIE = {
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
    cojo: REFERENTIEL_EXTERNE,
    expression_reguliere: STANDARD
  }.merge(INSTANCE_TYPE_DE_CHAMP_TO_CATEGORIE)

  enum type_champs: {
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
    expression_reguliere: 'expression_reguliere'
  }.merge(INSTANCE_TYPE_CHAMPS)

  INSTANCE_OPTIONS = [:parcelles, :batiments, :zones_manuelles, :min, :max, :level, :accredited_users, :table_id]
  INSTANCE_CHAMPS_PARAMS = [:numero_dn, :date_de_naissance]

  ROUTABLE_TYPES = [
    type_champs.fetch(:drop_down_list),
    type_champs.fetch(:commune_de_polynesie),
    type_champs.fetch(:code_postal_de_polynesie),
    type_champs.fetch(:communes),
    type_champs.fetch(:departements),
    type_champs.fetch(:regions),
    type_champs.fetch(:epci)
  ]

  PRIVATE_ONLY_TYPES = [
    type_champs.fetch(:engagement_juridique)
  ]

  store_accessor :options,
                 *INSTANCE_OPTIONS,
                 :cadastres,
                 :old_pj,
                 :drop_down_options,
                 :skip_pj_validation,
                 :skip_content_type_pj_validation,
                 :drop_down_secondary_libelle,
                 :drop_down_secondary_description,
                 :drop_down_other,
                 :character_limit,
                 :expression_reguliere,
                 :expression_reguliere_exemple_text,
                 :expression_reguliere_error_message,
                 :collapsible_explanation_enabled,
                 :collapsible_explanation_text,
                 :header_section_level

  has_many :revision_types_de_champ, -> { revision_ordered }, class_name: 'ProcedureRevisionTypeDeChamp', dependent: :destroy, inverse_of: :type_de_champ
  has_one :revision_type_de_champ, -> { revision_ordered }, class_name: 'ProcedureRevisionTypeDeChamp', inverse_of: false
  has_many :revisions, -> { ordered }, through: :revision_types_de_champ
  has_one :revision, through: :revision_type_de_champ
  has_one :procedure, through: :revision

  delegate :estimated_fill_duration, :estimated_read_duration, :tags_for_template, :libelles_for_export, :libelle_for_export, :primary_options, :secondary_options, to: :dynamic_type
  delegate :used_by_routing_rules?, to: :revision_type_de_champ

  class WithIndifferentAccess
    def self.load(options)
      options&.with_indifferent_access
    end

    def self.dump(options)
      options
    end
  end

  serialize :options, WithIndifferentAccess

  serialize :condition, LogicSerializer

  after_initialize :set_dynamic_type
  after_create :populate_stable_id

  attr_reader :dynamic_type

  scope :public_only, -> { where(private: false) }
  scope :private_only, -> { where(private: true) }
  scope :repetition, -> { where(type_champ: type_champs.fetch(:repetition)) }
  scope :not_repetition, -> { where.not(type_champ: type_champs.fetch(:repetition)) }
  scope :not_condition, -> { where(condition: nil) }
  scope :fillable, -> { where.not(type_champ: [type_champs.fetch(:header_section), type_champs.fetch(:explication)]) }

  scope :dubious, -> {
    where("unaccent(types_de_champ.libelle) ~* unaccent(?)", DubiousProcedure.forbidden_regexp)
      .where(type_champ: [TypeDeChamp.type_champs.fetch(:text), TypeDeChamp.type_champs.fetch(:textarea)])
  }

  has_many :champ, inverse_of: :type_de_champ, dependent: :destroy do
    def build(params = {})
      super(params.merge(proxy_association.owner.params_for_champ))
    end

    def create(params = {})
      super(params.merge(proxy_association.owner.params_for_champ))
    end
  end

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

  before_validation :check_mandatory
  before_validation :normalize_libelle

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
      type: self.class.type_champ_to_champ_class_name(type_champ),
      stable_id:,
      stream: 'main'
    }
  end

  def build_champ(params = {})
    champ.build(params)
  end

  def check_mandatory
    if non_fillable?
      self.mandatory = false
    else
      true
    end
  end

  def only_present_on_draft?
    revisions.one? && revisions.first.draft?
  end

  def drop_down_other?
    drop_down_other == "1" || drop_down_other == true
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
      TypeDeChamp.type_champs.fetch(:annuaire_education),
      TypeDeChamp.type_champs.fetch(:dossier_link),
      TypeDeChamp.type_champs.fetch(:siret),
      TypeDeChamp.type_champs.fetch(:rna)
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

  def self.is_choice_type_from(type_champ)
    return false if type_champ == TypeDeChamp.type_champs.fetch(:linked_drop_down_list) # To remove when we stop using linked_drop_down_list
    TYPE_DE_CHAMP_TO_CATEGORIE[type_champ.to_sym] == CHOICE || type_champ.in?([TypeDeChamp.type_champs.fetch(:departements), TypeDeChamp.type_champs.fetch(:regions)])
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

  def multiple_drop_down_list?
    type_champ == TypeDeChamp.type_champs.fetch(:multiple_drop_down_list)
  end

  def linked_drop_down_list?
    type_champ == TypeDeChamp.type_champs.fetch(:linked_drop_down_list)
  end

  def yes_no?
    type_champ == TypeDeChamp.type_champs.fetch(:yes_no)
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

  def integer_number?
    type_champ == TypeDeChamp.type_champs.fetch(:integer_number)
  end

  def decimal_number?
    type_champ == TypeDeChamp.type_champs.fetch(:decimal_number)
  end

  def date?
    type_champ == TypeDeChamp.type_champs.fetch(:date)
  end

  def textarea?
    type_champ == TypeDeChamp.type_champs.fetch(:textarea)
  end

  def titre_identite?
    type_champ == TypeDeChamp.type_champs.fetch(:titre_identite)
  end

  def carte?
    type_champ == TypeDeChamp.type_champs.fetch(:carte)
  end

  def visa?
    type_champ == TypeDeChamp.type_champs.fetch(:visa)
  end

  def referentiel_de_polynesie?
    type_champ == TypeDeChamp.type_champs.fetch(:referentiel_de_polynesie)
  end

  def te_fenua?
    type_champ == TypeDeChamp.type_champs.fetch(:te_fenua)
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

  def departement?
    type_champ == TypeDeChamp.type_champs.fetch(:departements)
  end

  def region?
    type_champ == TypeDeChamp.type_champs.fetch(:regions)
  end

  def mesri?
    type_champ == TypeDeChamp.type_champs.fetch(:mesri)
  end

  def datetime?
    type_champ == TypeDeChamp.type_champs.fetch(:datetime)
  end

  def checkbox?
    type_champ == TypeDeChamp.type_champs.fetch(:checkbox)
  end

  def expression_reguliere?
    type_champ == TypeDeChamp.type_champs.fetch(:expression_reguliere)
  end

  def public?
    !private?
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
    errs = []
    previous_level = previous_section_level(upper_tdcs)

    current_level = header_section_level_value.to_i
    difference = current_level - previous_level
    if current_level > previous_level && difference != 1
      errs << I18n.t('activerecord.errors.type_de_champ.attributes.header_section_level.gap_error', level: current_level - previous_level - 1)
    end
    errs
  end

  def current_section_level(revision)
    tdcs = private? ? revision.types_de_champ_private.to_a : revision.types_de_champ_public.to_a

    previous_section_level(tdcs.take(tdcs.find_index(self)))
  end

  def level_for_revision(revision)
    rtdc = revision.revision_types_de_champ.includes(:type_de_champ, parent: :type_de_champ).find { |rtdc| rtdc.stable_id == stable_id }
    if rtdc.child?
      header_section_level_value.to_i + rtdc.parent.type_de_champ.current_section_level(revision)
    elsif header_section_level_value
      header_section_level_value.to_i
    else
      0
    end
  end

  def self.filter_hash_type(type_champ)
    if is_choice_type_from(type_champ)
      :enum
    else
      :text
    end
  end

  def self.filter_hash_value_column(type_champ)
    if type_champ.in?([TypeDeChamp.type_champs.fetch(:departements), TypeDeChamp.type_champs.fetch(:regions)])
      :external_id
    else
      :value
    end
  end

  def options_for_select
    if departement?
      APIGeoService.departements.map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }
    elsif region?
      APIGeoService.regions.map { [_1[:name], _1[:code]] }
    elsif choice_type?
      if drop_down_list?
        drop_down_list_enabled_non_empty_options
      elsif yes_no?
        Champs::YesNoChamp.options
      elsif checkbox?
        Champs::CheckboxChamp.options
      end
    end
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

  def drop_down_list_enabled_non_empty_options(other: false)
    list_options = (drop_down_list_options - drop_down_list_disabled_options).reject(&:empty?)

    if other && drop_down_other?
      list_options + [[I18n.t('shared.champs.drop_down_list.other'), Champs::DropDownListChamp::OTHER]]
    else
      list_options
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

  def accredited_user_string
    if accredited_user_list.present?
      accredited_user_list.reject(&:empty?).join("\r\n")
    else
      ''
    end
  end

  def accredited_user_string=(value)
    self.accredited_users = parse_accredited_user_string(value)
  end

  def accredited_user_list?
    accredited_user_list.any?
  end

  def accredited_user_list
    accredited_users.presence || []
  end

  def available_tables
    ReferentielDePolynesie::API.available_tables.map { [_1[:name], _1[:id]] }
  end

  def to_typed_id
    GraphQL::Schema::UniqueWithinType.encode('Champ', stable_id)
  end

  def editable_options=(options)
    self.options.merge!(options)
  end

  def editable_options
    layers = if carte?
      TypesDeChamp::CarteTypeDeChamp::LAYERS
    elsif te_fenua?
      TypesDeChamp::TeFenuaTypeDeChamp::LAYERS
    else
      []
    end
    layers = layers.map do |layer|
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
    when type_champs.fetch(:annuaire_education),
      type_champs.fetch(:carte),
      type_champs.fetch(:piece_justificative),
      type_champs.fetch(:titre_identite),
      type_champs.fetch(:rna),
      type_champs.fetch(:siret),
      type_champs.fetch(:numero_dn),
      type_champs.fetch(:te_fenua),
      type_champs.fetch(:referentiel_de_polynesie)
      false
    else
      true
    end
  end

  def routable?
    type_champ.in?(ROUTABLE_TYPES)
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
    if row_id.blank?
      stable_id.to_s
    else
      "#{stable_id}-#{row_id}"
    end
  end

  class << self
    def champ_value(type_champ, champ)
      dynamic_type_class = type_champ_to_class_name(type_champ).constantize
      if use_default_value?(type_champ, champ)
        dynamic_type_class.champ_default_value
      else
        dynamic_type_class.champ_value(champ)
      end
    end

    def champ_value_for_api(type_champ, champ, version = 2)
      dynamic_type_class = type_champ_to_class_name(type_champ).constantize
      if use_default_value?(type_champ, champ)
        dynamic_type_class.champ_default_api_value(version)
      else
        dynamic_type_class.champ_value_for_api(champ, version)
      end
    end

    def champ_value_for_export(type_champ, champ, path = :value)
      dynamic_type_class = type_champ_to_class_name(type_champ).constantize
      if use_default_value?(type_champ, champ)
        dynamic_type_class.champ_default_export_value(path)
      else
        dynamic_type_class.champ_value_for_export(champ, path)
      end
    end

    def champ_value_for_tag(type_champ, champ, path = :value)
      if use_default_value?(type_champ, champ)
        ''
      else
        dynamic_type_class = type_champ_to_class_name(type_champ).constantize
        dynamic_type_class.champ_value_for_tag(champ, path)
      end
    end

    def type_champ_to_champ_class_name(type_champ)
      "Champs::#{type_champ.classify}Champ"
    end

    def type_champ_to_class_name(type_champ)
      "TypesDeChamp::#{type_champ.classify}TypeDeChamp"
    end

    private

    def use_default_value?(type_champ, champ)
      # no champ
      return true if champ.nil?
      # type de champ on the revision changed
      return true if type_champ_to_champ_class_name(type_champ) != champ.type
      # special case for linked drop down champ – it's blank implementation is not what you think
      return champ.value.blank? if type_champ == TypeDeChamp.type_champs.fetch(:linked_drop_down_list)

      champ.blank?
    end
  end

  private

  DEFAULT_EMPTY = ['']

  def parse_drop_down_list_value(value)
    value = value ? value.split("\r\n").map(&:strip).join("\r\n") : ''
    result = value.split(/[\r\n]|[\r]|[\n]|[\n\r]/).reject(&:empty?)
    result.blank? ? [] : DEFAULT_EMPTY + result
  end

  def parse_accredited_user_string(value)
    value.blank? ? [] : value.split(/\s*[\r\n]+\s*/).map(&:downcase)
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

  def normalize_libelle
    self.libelle&.strip!
  end
end
