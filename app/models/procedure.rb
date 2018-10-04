class Procedure < ApplicationRecord
  MAX_DUREE_CONSERVATION = 36

  has_many :types_de_piece_justificative, -> { order "order_place ASC" }, dependent: :destroy
  has_many :types_de_champ, -> { public_only }, dependent: :destroy
  has_many :types_de_champ_private, -> { private_only }, class_name: 'TypeDeChamp', dependent: :destroy
  has_many :dossiers
  has_many :deleted_dossiers, dependent: :destroy

  has_one :module_api_carto, dependent: :destroy
  has_one :attestation_template, dependent: :destroy
  has_one :procedure_path, dependent: :destroy

  belongs_to :administrateur
  belongs_to :parent_procedure, class_name: 'Procedure'
  belongs_to :service

  has_many :assign_to, dependent: :destroy
  has_many :administrateurs_procedures
  has_many :administrateurs, through: :administrateurs_procedures
  has_many :gestionnaires, through: :assign_to

  has_one :initiated_mail, class_name: "Mails::InitiatedMail", dependent: :destroy
  has_one :received_mail, class_name: "Mails::ReceivedMail", dependent: :destroy
  has_one :closed_mail, class_name: "Mails::ClosedMail", dependent: :destroy
  has_one :refused_mail, class_name: "Mails::RefusedMail", dependent: :destroy
  has_one :without_continuation_mail, class_name: "Mails::WithoutContinuationMail", dependent: :destroy

  has_one_attached :notice
  has_one_attached :deliberation

  delegate :use_api_carto, to: :module_api_carto

  accepts_nested_attributes_for :types_de_champ, :reject_if => proc { |attributes| attributes['libelle'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :types_de_piece_justificative, :reject_if => proc { |attributes| attributes['libelle'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :module_api_carto
  accepts_nested_attributes_for :types_de_champ_private

  mount_uploader :logo, ProcedureLogoUploader

  default_scope { where(hidden_at: nil) }
  scope :brouillons,            -> { where(aasm_state: :brouillon) }
  scope :publiees,              -> { where(aasm_state: :publiee) }
  scope :archivees,             -> { where(aasm_state: :archivee) }
  scope :publiees_ou_archivees, -> { where(aasm_state: [:publiee, :archivee]) }
  scope :by_libelle,            -> { order(libelle: :asc) }
  scope :created_during,        -> (range) { where(created_at: range) }
  scope :cloned_from_library,   -> { where(cloned_from_library: true) }
  scope :avec_lien,             -> { joins(:procedure_path) }

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :description, presence: true, allow_blank: false, allow_nil: false
  validate :check_juridique
  validates :path, format: { with: /\A[a-z0-9_\-]{3,50}\z/ }, uniqueness: true, presence: true, allow_blank: false, allow_nil: true
  # FIXME: remove duree_conservation_required flag once all procedures are converted to the new style
  validates :duree_conservation_dossiers_dans_ds, allow_nil: false, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_DUREE_CONSERVATION }, if: :durees_conservation_required
  validates :duree_conservation_dossiers_hors_ds, allow_nil: false, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: :durees_conservation_required
  validates :duree_conservation_dossiers_dans_ds, allow_nil: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_DUREE_CONSERVATION }, unless: :durees_conservation_required
  validates :duree_conservation_dossiers_hors_ds, allow_nil: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, unless: :durees_conservation_required

  before_save :update_juridique_required
  before_save :update_durees_conservation_required

  include AASM

  aasm whiny_persistence: true do
    state :brouillon, initial: true
    state :publiee
    state :archivee
    state :hidden

    event :publish, after: :after_publish, guard: :can_publish? do
      transitions from: :brouillon, to: :publiee
    end

    event :reopen, after: :after_reopen, guard: :can_publish? do
      transitions from: :archivee, to: :publiee
    end

    event :archive, after: :after_archive do
      transitions from: :publiee, to: :archivee
    end

    event :hide, after: :after_hide do
      transitions from: :brouillon, to: :hidden
      transitions from: :publiee, to: :hidden
      transitions from: :archivee, to: :hidden
    end
  end

  def publish_or_reopen!(path)
    if archivee? && may_reopen?(path)
      reopen!(path)
    elsif may_publish?(path)
      reset!
      publish!(path)
    end
  end

  def publish_with_path!(path)
    procedure_path = ProcedurePath
      .where(administrateur: administrateur)
      .find_by(path: path)

    if procedure_path.present?
      procedure_path.publish!(self)
    else
      create_procedure_path!(administrateur: administrateur, path: path)
    end
    update!(path: path)
  end

  def reset!
    if locked?
      raise "Can not reset a locked procedure."
    else
      dossiers.destroy_all
    end
  end

  def locked?
    publiee_ou_archivee?
  end

  def path_available?(path)
    !ProcedurePath.where.not(procedure: self).exists?(path: path)
  end

  def path_is_mine?(path)
    ProcedurePath.where.not(procedure: self).mine?(administrateur, path)
  end

  # This method is needed for transition. Eventually this will be the same as brouillon?.
  def brouillon_avec_lien?
    Flipflop.publish_draft? && brouillon? && path.present?
  end

  def publiee_ou_archivee?
    publiee? || archivee?
  end

  # Warning: dossier after_save build_default_champs must be removed
  # to save a dossier created from this method
  def new_dossier
    champs = types_de_champ
      .ordered
      .map { |tdc| tdc.champ.build }

    champs_private = types_de_champ_private
      .ordered
      .map { |tdc| tdc.champ.build }

    Dossier.new(procedure: self, champs: champs, champs_private: champs_private)
  end

  def path
    read_attribute(:path) || procedure_path&.path
  end

  def default_path
    libelle&.parameterize&.first(50)
  end

  def organisation_name
    service&.nom || organisation
  end

  def types_de_champ_ordered
    types_de_champ.order(:order_place)
  end

  def types_de_champ_private_ordered
    types_de_champ_private.order(:order_place)
  end

  def all_types_de_champ
    types_de_champ + types_de_champ_private
  end

  def self.active(id)
    publiees.find(id)
  end

  def switch_types_de_champ(index_of_first_element)
    switch_list_order(types_de_champ_ordered, index_of_first_element)
  end

  def switch_types_de_champ_private(index_of_first_element)
    switch_list_order(types_de_champ_private_ordered, index_of_first_element)
  end

  def switch_types_de_piece_justificative(index_of_first_element)
    switch_list_order(types_de_piece_justificative, index_of_first_element)
  end

  def switch_list_order(list, index_of_first_element)
    if index_of_first_element < 0 ||
      index_of_first_element == list.count - 1 ||
      list.count < 1

      false
    else
      list[index_of_first_element].update(order_place: index_of_first_element + 1)
      list[index_of_first_element + 1].update(order_place: index_of_first_element)

      true
    end
  end

  def clone(admin, from_library)
    procedure = self.deep_clone(include:
      {
        types_de_piece_justificative: nil,
        module_api_carto: nil,
        attestation_template: nil,
        types_de_champ: :drop_down_list,
        types_de_champ_private: :drop_down_list
      })
    procedure.path = nil
    procedure.aasm_state = :brouillon
    procedure.test_started_at = nil
    procedure.archived_at = nil
    procedure.published_at = nil
    procedure.logo_secure_token = nil
    procedure.remote_logo_url = self.logo_url

    [:notice, :deliberation].each { |attachment| clone_attachment(procedure, attachment) }

    procedure.administrateur = admin
    procedure.initiated_mail = initiated_mail&.dup
    procedure.received_mail = received_mail&.dup
    procedure.closed_mail = closed_mail&.dup
    procedure.refused_mail = refused_mail&.dup
    procedure.without_continuation_mail = without_continuation_mail&.dup

    procedure.cloned_from_library = from_library
    procedure.parent_procedure = self

    if from_library
      procedure.service = nil
    end

    procedure
  end

  def whitelisted?
    whitelisted_at.present?
  end

  def total_dossier
    self.dossiers.state_not_brouillon.size
  end

  def export_filename
    procedure_identifier = path || "procedure-#{id}"
    "dossiers_#{procedure_identifier}_#{Time.now.strftime('%Y-%m-%d_%H-%M')}"
  end

  def generate_export
    exportable_dossiers = dossiers.downloadable_sorted

    headers = exportable_dossiers&.first&.export_headers || []
    data = exportable_dossiers.any? ? exportable_dossiers.map(&:export_values) : [[]]

    {
      headers: headers,
      data: data
    }
  end

  def procedure_overview(start_date)
    ProcedureOverview.new(self, start_date)
  end

  def initiated_mail_template
    initiated_mail || Mails::InitiatedMail.default_for_procedure(self)
  end

  def received_mail_template
    received_mail || Mails::ReceivedMail.default_for_procedure(self)
  end

  def closed_mail_template
    closed_mail || Mails::ClosedMail.default_for_procedure(self)
  end

  def refused_mail_template
    refused_mail || Mails::RefusedMail.default_for_procedure(self)
  end

  def without_continuation_mail_template
    without_continuation_mail || Mails::WithoutContinuationMail.default_for_procedure(self)
  end

  def fields
    DossierFieldService.new.fields(self)
  end

  def fields_for_select
    fields.map do |field|
      [field['label'], "#{field['table']}/#{field['column']}"]
    end
  end

  def self.default_sort
    {
      'table' => 'self',
      'column' => 'id',
      'order' => 'desc'
    }
  end

  def whitelist!
    update_attribute('whitelisted_at', DateTime.now)
  end

  def closed_mail_template_attestation_inconsistency_state
    # As an optimization, don’t check the predefined templates (they are presumed correct)
    if closed_mail.present?
      tag_present = closed_mail.body.include?("--lien attestation--")
      if attestation_template&.activated? && !tag_present
        :missing_tag
      elsif !attestation_template&.activated? && tag_present
        :extraneous_tag
      end
    end
  end

  def mean_traitement_time
    mean_time(:en_construction_at, :processed_at)
  end

  def mean_verification_time
    mean_time(:en_construction_at, :en_instruction_at)
  end

  def mean_instruction_time
    mean_time(:en_instruction_at, :processed_at)
  end

  private

  def can_publish?(path)
    procedure_path = ProcedurePath.find_by(path: path)
    if procedure_path.present?
      administrateur.owns?(procedure_path)
    else
      true
    end
  end

  def after_publish(path)
    update!(published_at: Time.now)

    publish_with_path!(path)
  end

  def after_archive
    update!(archived_at: Time.now, path: nil)
  end

  def after_hide
    now = Time.now
    update!(hidden_at: now, path: nil)
    procedure_path&.hide!
    dossiers.update_all(hidden_at: now)
  end

  def after_reopen(path)
    update!(published_at: Time.now, archived_at: nil)

    publish_with_path!(path)
  end

  def update_juridique_required
    self.juridique_required ||= (cadre_juridique.present? || deliberation.attached?)
    true
  end

  def clone_attachment(cloned_procedure, attachment_symbol)
    attachment = send(attachment_symbol)
    if attachment.attached?
      response = Typhoeus.get(attachment.service_url, timeout: 5)
      if response.success?
        cloned_procedure.send(attachment_symbol).attach(
          io: StringIO.new(response.body),
          filename: attachment.filename
        )
      end
    end
  end

  def check_juridique
    if juridique_required? && (cadre_juridique.blank? && !deliberation.attached?)
      errors.add(:cadre_juridique, " : veuillez remplir le texte de loi ou la délibération")
    end
  end

  def update_durees_conservation_required
    self.durees_conservation_required ||= duree_conservation_dossiers_hors_ds.present? && duree_conservation_dossiers_dans_ds.present?
    true
  end

  def mean_time(start_attribute, end_attribute)
    times = dossiers
      .state_termine
      .pluck(start_attribute, end_attribute)
      .map { |(start_date, end_date)| end_date - start_date }

    if times.present?
      times.sum.fdiv(times.size).ceil
    end
  end
end
