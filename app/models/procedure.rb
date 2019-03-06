require Rails.root.join('lib', 'percentile')

class Procedure < ApplicationRecord
  MAX_DUREE_CONSERVATION = 36

  has_many :types_de_piece_justificative, -> { ordered }, dependent: :destroy
  has_many :types_de_champ, -> { root.public_only.ordered }, dependent: :destroy
  has_many :types_de_champ_private, -> { root.private_only.ordered }, class_name: 'TypeDeChamp', dependent: :destroy
  has_many :dossiers, dependent: :restrict_with_exception
  has_many :deleted_dossiers, dependent: :destroy

  has_one :module_api_carto, dependent: :destroy
  has_one :attestation_template, dependent: :destroy

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

  accepts_nested_attributes_for :types_de_champ, reject_if: proc { |attributes| attributes['libelle'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :types_de_champ_private, reject_if: proc { |attributes| attributes['libelle'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :types_de_piece_justificative, reject_if: proc { |attributes| attributes['libelle'].blank? }, allow_destroy: true

  mount_uploader :logo, ProcedureLogoUploader

  default_scope { where(hidden_at: nil) }
  scope :brouillons,            -> { where(aasm_state: :brouillon) }
  scope :publiees,              -> { where(aasm_state: :publiee) }
  scope :archivees,             -> { where(aasm_state: :archivee) }
  scope :publiees_ou_archivees, -> { where(aasm_state: [:publiee, :archivee]) }
  scope :by_libelle,            -> { order(libelle: :asc) }
  scope :created_during,        -> (range) { where(created_at: range) }
  scope :cloned_from_library,   -> { where(cloned_from_library: true) }
  scope :avec_lien,             -> { where.not(path: nil) }

  scope :for_api, -> {
    includes(
      :administrateur,
      :types_de_champ_private,
      :types_de_champ,
      :types_de_piece_justificative,
      :module_api_carto
    )
  }

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :description, presence: true, allow_blank: false, allow_nil: false
  validate :check_juridique
  validates :path, format: { with: /\A[a-z0-9_\-]{3,50}\z/ }, uniqueness: { scope: :aasm_state, case_sensitive: false }, presence: true, allow_blank: false, allow_nil: true
  # FIXME: remove duree_conservation_required flag once all procedures are converted to the new style
  validates :duree_conservation_dossiers_dans_ds, allow_nil: false, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_DUREE_CONSERVATION }, if: :durees_conservation_required
  validates :duree_conservation_dossiers_hors_ds, allow_nil: false, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: :durees_conservation_required
  validates :duree_conservation_dossiers_dans_ds, allow_nil: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_DUREE_CONSERVATION }, unless: :durees_conservation_required
  validates :duree_conservation_dossiers_hors_ds, allow_nil: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, unless: :durees_conservation_required

  before_save :update_juridique_required
  before_save :update_durees_conservation_required
  before_create :ensure_path_exists

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

    event :draft, after: :after_draft do
      transitions from: :publiee, to: :brouillon
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

  # This method is needed for transition. Eventually this will be the same as brouillon?.
  def brouillon_avec_lien?
    brouillon? && path.present?
  end

  def publiee_ou_archivee?
    publiee? || archivee?
  end

  def expose_legacy_carto_api?
    module_api_carto&.use_api_carto? && module_api_carto&.migrated?
  end

  # Warning: dossier after_save build_default_champs must be removed
  # to save a dossier created from this method
  def new_dossier
    Dossier.new(procedure: self, champs: build_champs, champs_private: build_champs_private)
  end

  def build_champs
    types_de_champ.map(&:build_champ)
  end

  def build_champs_private
    types_de_champ_private.map(&:build_champ)
  end

  def default_path
    libelle&.parameterize&.first(50)
  end

  def organisation_name
    service&.nom || organisation
  end

  def self.active(id)
    publiees.find(id)
  end

  def switch_types_de_champ(index_of_first_element)
    switch_list_order(types_de_champ, index_of_first_element)
  end

  def switch_types_de_champ_private(index_of_first_element)
    switch_list_order(types_de_champ_private, index_of_first_element)
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
      reload

      true
    end
  end

  def clone(admin, from_library)
    is_different_admin = !admin.owns?(self)

    populate_champ_stable_ids
    procedure = self.deep_clone(include:
      {
        attestation_template: nil,
        types_de_champ: [:drop_down_list, types_de_champ: :drop_down_list],
        types_de_champ_private: [:drop_down_list, types_de_champ: :drop_down_list]
      })
    procedure.path = nil
    procedure.aasm_state = :brouillon
    procedure.test_started_at = nil
    procedure.archived_at = nil
    procedure.published_at = nil
    procedure.logo_secure_token = nil
    procedure.remote_logo_url = self.logo_url
    procedure.lien_notice = nil

    [:notice, :deliberation].each { |attachment| clone_attachment(procedure, attachment) }

    procedure.types_de_champ += PiecesJustificativesService.types_pj_as_types_de_champ(self)
    if is_different_admin || from_library
      procedure.types_de_champ.each { |tdc| tdc.options&.delete(:old_pj) }
    end

    if is_different_admin
      procedure.administrateurs = [admin]
    else
      procedure.administrateurs = administrateurs
    end

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
    elsif self.service.present? && is_different_admin
      procedure.service = self.service.clone_and_assign_to_administrateur(admin)
    end

    admin.gestionnaire.assign_to_procedure(procedure)

    procedure
  end

  def whitelisted?
    whitelisted_at.present?
  end

  def has_old_pjs?
    types_de_piece_justificative.any?
  end

  def total_dossier
    self.dossiers.state_not_brouillon.size
  end

  def export_filename(format)
    procedure_identifier = path || "procedure-#{id}"
    "dossiers_#{procedure_identifier}_#{Time.zone.now.strftime('%Y-%m-%d_%H-%M')}.#{format}"
  end

  def export(options = {})
    ProcedureExportService.new(self, **options.to_h.symbolize_keys)
  end

  def to_csv(options = {})
    export(options).to_csv
  end

  def to_xlsx(options = {})
    export(options).to_xlsx
  end

  def to_ods(options = {})
    export(options).to_ods
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

  def self.default_sort
    {
      'table' => 'self',
      'column' => 'id',
      'order' => 'desc'
    }
  end

  def whitelist!
    update_attribute('whitelisted_at', Time.zone.now)
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

  def usual_traitement_time
    percentile_time(:en_construction_at, :processed_at, 90)
  end

  def usual_verification_time
    percentile_time(:en_construction_at, :en_instruction_at, 90)
  end

  def usual_instruction_time
    percentile_time(:en_instruction_at, :processed_at, 90)
  end

  PATH_AVAILABLE = :available
  PATH_AVAILABLE_PUBLIEE = :available_publiee
  PATH_NOT_AVAILABLE = :not_available
  PATH_NOT_AVAILABLE_BROUILLON = :not_available_brouillon
  PATH_CAN_PUBLISH = [PATH_AVAILABLE, PATH_AVAILABLE_PUBLIEE]

  def path_availability(path)
    Procedure.path_availability(administrateur, path, id)
  end

  def self.path_availability(administrateur, path, exclude_id = nil)
    if exclude_id.present?
      procedure = where.not(id: exclude_id).find_by(path: path)
    else
      procedure = find_by(path: path)
    end

    if procedure.blank?
      PATH_AVAILABLE
    elsif administrateur.owns?(procedure)
      if procedure.brouillon?
        PATH_NOT_AVAILABLE_BROUILLON
      else
        PATH_AVAILABLE_PUBLIEE
      end
    else
      PATH_NOT_AVAILABLE
    end
  end

  def self.find_with_path(path)
    where.not(aasm_state: :archivee).where("path LIKE ?", "%#{path}%")
  end

  def populate_champ_stable_ids
    TypeDeChamp.where(procedure: self, stable_id: nil).find_each do |type_de_champ|
      type_de_champ.update_column(:stable_id, type_de_champ.id)
    end
  end

  def missing_steps
    result = []

    if service.nil?
      result << :service
    end

    if gestionnaires.empty?
      result << :instructeurs
    end

    result
  end

  private

  def claim_path_ownership!(path)
    procedure = Procedure.where(administrateur: administrateur).find_by(path: path)

    if procedure&.publiee? && procedure != self
      procedure.archive!
    end

    update!(path: path)
  end

  def can_publish?(path)
    path_availability(path).in?(PATH_CAN_PUBLISH)
  end

  def after_publish(path)
    update!(published_at: Time.zone.now)

    claim_path_ownership!(path)
  end

  def after_reopen(path)
    update!(published_at: Time.zone.now, archived_at: nil)

    claim_path_ownership!(path)
  end

  def after_archive
    update!(archived_at: Time.zone.now, path: nil)
  end

  def after_hide
    now = Time.zone.now
    update!(hidden_at: now, path: nil)
    dossiers.update_all(hidden_at: now)
  end

  def after_draft
    update!(published_at: nil)
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

  def percentile_time(start_attribute, end_attribute, p)
    times = dossiers
      .state_termine
      .where(end_attribute => 1.month.ago..Time.zone.now)
      .pluck(start_attribute, end_attribute)
      .map { |(start_date, end_date)| end_date - start_date }

    if times.present?
      times.percentile(p).ceil
    end
  end

  def ensure_path_exists
    if self.path.nil?
      self.path = SecureRandom.uuid
    end
  end
end
