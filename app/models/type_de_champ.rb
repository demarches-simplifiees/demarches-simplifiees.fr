# == Schema Information
#
# Table name: types_de_champ
#
#  id          :integer          not null, primary key
#  description :text
#  libelle     :string
#  mandatory   :boolean          default(FALSE)
#  options     :jsonb
#  order_place :integer
#  private     :boolean          default(FALSE), not null
#  type_champ  :string
#  created_at  :datetime
#  updated_at  :datetime
#  parent_id   :bigint
#  revision_id :bigint
#  stable_id   :bigint
#
class TypeDeChamp < ApplicationRecord
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
    pays: 'pays',
    regions: 'regions',
    departements: 'departements',
    communes: 'communes',
    engagement: 'engagement',
    header_section: 'header_section',
    explication: 'explication',
    dossier_link: 'dossier_link',
    piece_justificative: 'piece_justificative',
    siret: 'siret',
    carte: 'carte',
    repetition: 'repetition',
    titre_identite: 'titre_identite',
    iban: 'iban',
    annuaire_education: 'annuaire_education'
  }

  belongs_to :revision, class_name: 'ProcedureRevision', optional: true
  has_one :procedure, through: :revision

  belongs_to :parent, class_name: 'TypeDeChamp', optional: true
  has_many :types_de_champ, -> { ordered }, foreign_key: :parent_id, class_name: 'TypeDeChamp', inverse_of: :parent, dependent: :destroy

  store_accessor :options, :cadastres, :old_pj, :drop_down_options, :skip_pj_validation, :skip_content_type_pj_validation
  has_many :revision_types_de_champ, class_name: 'ProcedureRevisionTypeDeChamp', dependent: :destroy, inverse_of: :type_de_champ
  has_many :revisions, through: :revision_types_de_champ

  delegate :tags_for_template, to: :dynamic_type

  class WithIndifferentAccess
    def self.load(options)
      options&.with_indifferent_access
    end

    def self.dump(options)
      options
    end
  end

  serialize :options, WithIndifferentAccess

  after_initialize :set_dynamic_type
  after_create :populate_stable_id

  attr_reader :dynamic_type

  scope :public_only, -> { where(private: false) }
  scope :private_only, -> { where(private: true) }
  scope :ordered, -> { order(order_place: :asc) }
  scope :root, -> { where(parent_id: nil) }
  scope :repetition, -> { where(type_champ: type_champs.fetch(:repetition)) }

  has_many :champ, inverse_of: :type_de_champ, dependent: :destroy do
    def build(params = {})
      super(params.merge(proxy_association.owner.params_for_champ))
    end

    def create(params = {})
      super(params.merge(proxy_association.owner.params_for_champ))
    end
  end

  has_one_attached :piece_justificative_template

  accepts_nested_attributes_for :types_de_champ, reject_if: proc { |attributes| attributes['libelle'].blank? }, allow_destroy: true

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :type_champ, presence: true, allow_blank: false, allow_nil: false

  before_validation :check_mandatory
  before_save :remove_piece_justificative_template, if: -> { type_champ_changed? }
  before_save :remove_drop_down_list, if: -> { type_champ_changed? }
  before_save :remove_repetition, if: -> { type_champ_changed? }

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

  def build_champ
    dynamic_type.build_champ
  end

  def check_mandatory
    if non_fillable?
      self.mandatory = false
    else
      true
    end
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

  def header_section?
    type_champ == TypeDeChamp.type_champs.fetch(:header_section)
  end

  def linked_drop_down_list?
    type_champ == TypeDeChamp.type_champs.fetch(:linked_drop_down_list)
  end

  def exclude_from_view?
    type_champ == TypeDeChamp.type_champs.fetch(:explication)
  end

  def repetition?
    type_champ == TypeDeChamp.type_champs.fetch(:repetition)
  end

  def dossier_link?
    type_champ == TypeDeChamp.type_champs.fetch(:dossier_link)
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

  def public?
    !private?
  end

  def self.type_champ_to_class_name(type_champ)
    "TypesDeChamp::#{type_champ.classify}TypeDeChamp"
  end

  def piece_justificative_template_url
    if piece_justificative_template.attached?
      Rails.application.routes.url_helpers.url_for(piece_justificative_template)
    end
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

  def to_typed_id
    GraphQL::Schema::UniqueWithinType.encode('Champ', stable_id)
  end

  def editable_options=(options)
    self.options.merge!(options)
  end

  def editable_options
    options.slice(:cadastres,
      :unesco,
      :arretes_protection,
      :conservatoire_littoral,
      :reserves_chasse_faune_sauvage,
      :reserves_biologiques,
      :reserves_naturelles,
      :natura_2000,
      :zones_humides,
      :znieff)
  end

  FEATURE_FLAGS = {}

  def self.type_de_champ_types_for(procedure, user)
    has_legacy_number = (procedure.types_de_champ + procedure.types_de_champ_private).any?(&:legacy_number?)

    type_champs.map do |type_champ|
      [I18n.t("activerecord.attributes.type_de_champ.type_champs.#{type_champ.last}"), type_champ.first]
    end.filter do |tdc|
      if tdc.last == TypeDeChamp.type_champs.fetch(:number)
        has_legacy_number
      else
        feature_name = FEATURE_FLAGS[tdc.last]
        feature_name.blank? || Flipper.enabled?(feature_name, user)
      end
    end
  end

  TYPES_DE_CHAMP_BASE = {
    except: [
      :created_at,
      :options,
      :order_place,
      :parent_id,
      :private,
      :procedure_id,
      :revision_id,
      :stable_id,
      :type,
      :updated_at
    ],
    methods: [
      :drop_down_list_value,
      :piece_justificative_template_filename,
      :piece_justificative_template_url,
      :editable_options
    ]
  }
  TYPES_DE_CHAMP = TYPES_DE_CHAMP_BASE
    .merge(include: { types_de_champ: TYPES_DE_CHAMP_BASE })

  def self.as_json_for_editor
    includes(piece_justificative_template_attachment: :blob, types_de_champ: [piece_justificative_template_attachment: :blob]).as_json(TYPES_DE_CHAMP)
  end

  def read_attribute_for_serialization(name)
    if name == 'id'
      stable_id
    else
      super
    end
  end

  private

  def parse_drop_down_list_value(value)
    value = value ? value.split("\r\n").map(&:strip).join("\r\n") : ''
    result = value.split(/[\r\n]|[\r]|[\n]|[\n\r]/).reject(&:empty?)
    result.blank? ? [] : [''] + result
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
    end
  end

  def remove_repetition
    if !repetition?
      types_de_champ.destroy_all
    end
  end

  def clone_attachments(original, kopy)
    if original.is_a?(TypeDeChamp)
      clone_attachment(:piece_justificative_template, original, kopy)
    end
  end

  def clone_attachment(attribute, original, kopy)
    original_attachment = original.send(attribute)
    if original_attachment.attached?
      kopy.send(attribute).attach({
        io: StringIO.new(original_attachment.download),
        filename: original_attachment.filename,
        content_type: original_attachment.content_type,
        # we don't want to run virus scanner on cloned file
        metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
      })
    end
  end
end
