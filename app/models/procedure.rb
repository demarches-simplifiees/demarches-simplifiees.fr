require Rails.root.join('lib', 'percentile')

class Procedure < ApplicationRecord
  self.ignored_columns = ['logo', 'logo_secure_token']

  include ProcedureStatsConcern

  MAX_DUREE_CONSERVATION = 36
  MAX_DUREE_CONSERVATION_EXPORT = 3.hours

  has_many :types_de_champ, -> { root.public_only.ordered }, inverse_of: :procedure, dependent: :destroy
  has_many :types_de_champ_private, -> { root.private_only.ordered }, class_name: 'TypeDeChamp', inverse_of: :procedure, dependent: :destroy
  has_many :deleted_dossiers, dependent: :destroy

  has_one :module_api_carto, dependent: :destroy
  has_one :attestation_template, dependent: :destroy

  belongs_to :parent_procedure, class_name: 'Procedure'
  belongs_to :service

  has_many :administrateurs_procedures
  has_many :administrateurs, through: :administrateurs_procedures, after_remove: -> (procedure, _admin) { procedure.validate! }
  has_many :groupe_instructeurs, dependent: :destroy

  has_many :dossiers, through: :groupe_instructeurs, dependent: :restrict_with_exception

  has_one :initiated_mail, class_name: "Mails::InitiatedMail", dependent: :destroy
  has_one :received_mail, class_name: "Mails::ReceivedMail", dependent: :destroy
  has_one :closed_mail, class_name: "Mails::ClosedMail", dependent: :destroy
  has_one :refused_mail, class_name: "Mails::RefusedMail", dependent: :destroy
  has_one :without_continuation_mail, class_name: "Mails::WithoutContinuationMail", dependent: :destroy

  has_one :defaut_groupe_instructeur, -> { order(:id) }, class_name: 'GroupeInstructeur', inverse_of: :procedure

  has_one_attached :logo
  has_one_attached :notice
  has_one_attached :deliberation

  has_one_attached :csv_export_file
  has_one_attached :xlsx_export_file
  has_one_attached :ods_export_file

  accepts_nested_attributes_for :types_de_champ, reject_if: proc { |attributes| attributes['libelle'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :types_de_champ_private, reject_if: proc { |attributes| attributes['libelle'].blank? }, allow_destroy: true

  default_scope { where(hidden_at: nil) }
  scope :brouillons,            -> { where(aasm_state: :brouillon) }
  scope :publiees,              -> { where(aasm_state: :publiee) }
  scope :archivees,             -> { where(aasm_state: :archivee) }
  scope :publiees_ou_archivees, -> { where(aasm_state: [:publiee, :archivee]) }
  scope :by_libelle,            -> { order(libelle: :asc) }
  scope :created_during,        -> (range) { where(created_at: range) }
  scope :cloned_from_library,   -> { where(cloned_from_library: true) }
  scope :declarative,           -> { where.not(declarative_with_state: nil) }

  scope :for_api, -> {
    includes(
      :administrateurs,
      :types_de_champ_private,
      :types_de_champ,
      :module_api_carto
    )
  }

  enum declarative_with_state: {
    en_instruction:  'en_instruction',
    accepte:         'accepte'
  }

  scope :for_api_v2, -> {
    includes(administrateurs: :user)
  }

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :description, presence: true, allow_blank: false, allow_nil: false
  validates :administrateurs, presence: true
  validates :lien_site_web, presence: true, if: :publiee?
  validate :validate_for_publication, on: :publication
  validate :check_juridique
  validates :path, presence: true, format: { with: /\A[a-z0-9_\-]{3,50}\z/ }, uniqueness: { scope: [:path, :archived_at, :hidden_at], case_sensitive: false }
  # FIXME: remove duree_conservation_required flag once all procedures are converted to the new style
  validates :duree_conservation_dossiers_dans_ds, allow_nil: false, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_DUREE_CONSERVATION }, if: :durees_conservation_required
  validates :duree_conservation_dossiers_hors_ds, allow_nil: false, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: :durees_conservation_required
  validates :duree_conservation_dossiers_dans_ds, allow_nil: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_DUREE_CONSERVATION }, unless: :durees_conservation_required
  validates :duree_conservation_dossiers_hors_ds, allow_nil: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, unless: :durees_conservation_required
  validates_with MonAvisEmbedValidator
  before_save :update_juridique_required
  before_save :update_durees_conservation_required
  after_initialize :ensure_path_exists
  before_save :ensure_path_exists
  after_create :ensure_default_groupe_instructeur

  include AASM

  aasm whiny_persistence: true do
    state :brouillon, initial: true
    state :publiee
    state :archivee
    state :hidden

    event :publish, before: :before_publish, after: :after_publish do
      transitions from: :brouillon, to: :publiee
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

  def publish_or_reopen!(administrateur)
    Procedure.transaction do
      if brouillon?
        reset!
      end

      other_procedure = other_procedure_with_path(path)
      if other_procedure.present? && administrateur.owns?(other_procedure)
        other_procedure.archive!
      end

      publish!
    end
  end

  def csv_export_stale?
    !csv_export_file.attached? || csv_export_file.created_at < MAX_DUREE_CONSERVATION_EXPORT.ago
  end

  def xlsx_export_stale?
    !xlsx_export_file.attached? || xlsx_export_file.created_at < MAX_DUREE_CONSERVATION_EXPORT.ago
  end

  def ods_export_stale?
    !ods_export_file.attached? || ods_export_file.created_at < MAX_DUREE_CONSERVATION_EXPORT.ago
  end

  def export_queued?(format)
    case format.to_sym
    when :csv
      return csv_export_queued?
    when :xlsx
      return xlsx_export_queued?
    when :ods
      return ods_export_queued?
    end
    false
  end

  def should_generate_export?(format)
    case format.to_sym
    when :csv
      return csv_export_stale? && !csv_export_queued?
    when :xlsx
      return xlsx_export_stale? && !xlsx_export_queued?
    when :ods
      return ods_export_stale? && !ods_export_queued?
    end
    false
  end

  def export_file(export_format)
    case export_format.to_sym
    when :csv
      csv_export_file
    when :xlsx
      xlsx_export_file
    when :ods
      ods_export_file
    end
  end

  def queue_export(instructeur, export_format)
    case export_format.to_sym
    when :csv
      update(csv_export_queued: true)
    when :xlsx
      update(xlsx_export_queued: true)
    when :ods
      update(ods_export_queued: true)
    end
    ExportProcedureJob.perform_later(self, instructeur, export_format)
  end

  def prepare_export_download(format)
    service = ProcedureExportV2Service.new(self, self.dossiers)
    filename = export_filename(format)

    case format.to_sym
    when :csv
      csv_export_file.attach(
        io: StringIO.new(service.to_csv),
        filename: filename,
        content_type: 'text/csv'
      )
      update(csv_export_queued: false)
    when :xlsx
      xlsx_export_file.attach(
        io: StringIO.new(service.to_xlsx),
        filename: filename,
        content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      )
      update(xlsx_export_queued: false)
    when :ods
      ods_export_file.attach(
        io: StringIO.new(service.to_ods),
        filename: filename,
        content_type: 'application/vnd.oasis.opendocument.spreadsheet'
      )
      update(ods_export_queued: false)
    end
  end

  def reset!
    if locked?
      raise "Can not reset a locked procedure."
    else
      groupe_instructeurs.each { |gi| gi.dossiers.destroy_all }
      purge_export_files
    end
  end

  def validate_for_publication
    old_attributes = self.slice(:aasm_state, :archived_at)
    self.aasm_state = :publiee
    self.archived_at = nil

    is_valid = validate

    self.attributes = old_attributes

    is_valid
  end

  def suggested_path(administrateur)
    if path_customized?
      return path
    end
    slug = libelle&.parameterize&.first(50)
    suggestion = slug
    counter = 1
    while !path_available?(administrateur, suggestion)
      counter = counter + 1
      suggestion = "#{slug}-#{counter}"
    end
    suggestion
  end

  def other_procedure_with_path(path)
    Procedure.publiees
      .where.not(id: self.id)
      .find_by(path: path)
  end

  def path_available?(administrateur, path)
    procedure = other_procedure_with_path(path)

    procedure.blank? || administrateur.owns?(procedure)
  end

  def purge_export_files
    xlsx_export_file.purge_later
    ods_export_file.purge_later
    csv_export_file.purge_later

    update(csv_export_queued: false, xlsx_export_queued: false, ods_export_queued: false)
  end

  def locked?
    publiee_ou_archivee?
  end

  def accepts_new_dossiers?
    !archivee?
  end

  def publiee_ou_archivee?
    publiee? || archivee?
  end

  def expose_legacy_carto_api?
    module_api_carto&.use_api_carto? && module_api_carto&.migrated?
  end

  def declarative?
    declarative_with_state.present?
  end

  def declarative_accepte?
    declarative_with_state == Procedure.declarative_with_states.fetch(:accepte)
  end

  # Warning: dossier after_save build_default_champs must be removed
  # to save a dossier created from this method
  def new_dossier
    Dossier.new(
      procedure: self,
      champs: build_champs,
      champs_private: build_champs_private,
      groupe_instructeur: defaut_groupe_instructeur
    )
  end

  def build_champs
    types_de_champ.map(&:build_champ)
  end

  def build_champs_private
    types_de_champ_private.map(&:build_champ)
  end

  def path_customized?
    !path.match?(/[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}/)
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
      }, &method(:clone_attachments))
    procedure.path = SecureRandom.uuid
    procedure.aasm_state = :brouillon
    procedure.test_started_at = nil
    procedure.archived_at = nil
    procedure.published_at = nil
    procedure.lien_notice = nil

    if is_different_admin || from_library
      procedure.types_de_champ.each { |tdc| tdc.options&.delete(:old_pj) }
    end

    if is_different_admin
      procedure.administrateurs = [admin]
    else
      procedure.administrateurs = administrateurs
    end

    procedure.initiated_mail = initiated_mail&.dup
    procedure.received_mail = received_mail&.dup
    procedure.closed_mail = closed_mail&.dup
    procedure.refused_mail = refused_mail&.dup
    procedure.without_continuation_mail = without_continuation_mail&.dup
    procedure.ask_birthday = false # see issue #4242

    procedure.cloned_from_library = from_library
    procedure.parent_procedure = self

    if from_library
      procedure.service = nil
    elsif self.service.present? && is_different_admin
      procedure.service = self.service.clone_and_assign_to_administrateur(admin)
    end

    procedure.save

    admin.instructeur.assign_to_procedure(procedure)

    procedure
  end

  def clone_attachments(original, kopy)
    if original.is_a?(TypeDeChamp)
      clone_attachment(:piece_justificative_template, original, kopy)
    elsif original.is_a?(Procedure)
      clone_attachment(:logo, original, kopy)
      clone_attachment(:notice, original, kopy)
      clone_attachment(:deliberation, original, kopy)
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

  def whitelisted?
    whitelisted_at.present?
  end

  def total_dossier
    self.dossiers.state_not_brouillon.size
  end

  def export_filename(format)
    procedure_identifier = path || "procedure-#{id}"
    "dossiers_#{procedure_identifier}_#{Time.zone.now.strftime('%Y-%m-%d_%H-%M')}.#{format}"
  end

  def export(dossiers, options = {})
    version = options.delete(:version)
    if version == 'v2'
      options.delete(:tables)
      ProcedureExportV2Service.new(self, dossiers, **options.to_h.symbolize_keys)
    else
      ProcedureExportService.new(self, dossiers, **options.to_h.symbolize_keys)
    end
  end

  def to_csv(dossiers, options = {})
    export(dossiers, options).to_csv
  end

  def to_xlsx(dossiers, options = {})
    export(dossiers, options).to_xlsx
  end

  def to_ods(dossiers, options = {})
    export(dossiers, options).to_ods
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

    if missing_instructeurs?
      result << :instructeurs
    end

    result
  end

  def move_type_de_champ(type_de_champ, new_index)
    types_de_champ, collection_attribute_name = if type_de_champ.parent&.repetition?
      if type_de_champ.parent.private?
        [type_de_champ.parent.types_de_champ, :types_de_champ_private_attributes]
      else
        [type_de_champ.parent.types_de_champ, :types_de_champ_attributes]
      end
    elsif type_de_champ.private?
      [self.types_de_champ_private, :types_de_champ_private_attributes]
    else
      [self.types_de_champ, :types_de_champ_attributes]
    end

    attributes = move_type_de_champ_attributes(types_de_champ.to_a, type_de_champ, new_index)

    if type_de_champ.parent&.repetition?
      attributes = [
        {
          id: type_de_champ.parent.id,
          libelle: type_de_champ.parent.libelle,
          types_de_champ_attributes: attributes
        }
      ]
    end

    update!(collection_attribute_name => attributes)
  end

  def process_dossiers!
    case declarative_with_state
    when Procedure.declarative_with_states.fetch(:en_instruction)
      dossiers
        .state_en_construction
        .find_each(&:passer_automatiquement_en_instruction!)
    when Procedure.declarative_with_states.fetch(:accepte)
      dossiers
        .state_en_construction
        .find_each(&:accepter_automatiquement!)
    end
  end

  def logo_url
    if logo.attached?
      Rails.application.routes.url_helpers.url_for(logo)
    else
      ActionController::Base.helpers.image_url("polynesie.png")
    end
  end

  def missing_instructeurs?
    !AssignTo.exists?(groupe_instructeur: groupe_instructeurs)
  end

  def routee?
    groupe_instructeurs.count > 1
  end

  private

  def move_type_de_champ_attributes(types_de_champ, type_de_champ, new_index)
    old_index = types_de_champ.index(type_de_champ)
    types_de_champ.insert(new_index, types_de_champ.delete_at(old_index))
      .map.with_index do |type_de_champ, index|
        {
          id: type_de_champ.id,
          libelle: type_de_champ.libelle,
          order_place: index
        }
      end
  end

  def before_publish
    update!(archived_at: nil)
  end

  def after_publish
    update!(published_at: Time.zone.now)
  end

  def after_archive
    update!(archived_at: Time.zone.now)
    purge_export_files
  end

  def after_hide
    now = Time.zone.now
    update!(hidden_at: now)
    dossiers.update_all(hidden_at: now)
    purge_export_files
  end

  def after_draft
    update!(published_at: nil)
  end

  def update_juridique_required
    self.juridique_required ||= (cadre_juridique.present? || deliberation.attached?)
    true
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
      .where.not(start_attribute => nil, end_attribute => nil)
      .where(end_attribute => 1.month.ago..Time.zone.now)
      .pluck(start_attribute, end_attribute)
      .map { |(start_date, end_date)| end_date - start_date }

    if times.present?
      times.percentile(p).ceil
    end
  end

  def ensure_path_exists
    if self.path.blank?
      self.path = SecureRandom.uuid
    end
  end

  def ensure_default_groupe_instructeur
    if self.groupe_instructeurs.empty?
      groupe_instructeurs.create(label: GroupeInstructeur::DEFAULT_LABEL)
    end
  end
end
