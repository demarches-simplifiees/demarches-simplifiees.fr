# == Schema Information
#
# Table name: dossiers
#
#  id                                                 :integer          not null, primary key
#  api_entreprise_job_exceptions                      :string           is an Array
#  archived                                           :boolean          default(FALSE)
#  autorisation_donnees                               :boolean
#  brouillon_close_to_expiration_notice_sent_at       :datetime
#  conservation_extension                             :interval         default(0 seconds)
#  declarative_triggered_at                           :datetime
#  deleted_user_email_never_send                      :string
#  depose_at                                          :datetime
#  en_construction_at                                 :datetime
#  en_construction_close_to_expiration_notice_sent_at :datetime
#  en_instruction_at                                  :datetime
#  for_procedure_preview                              :boolean          default(FALSE)
#  groupe_instructeur_updated_at                      :datetime
#  hidden_at                                          :datetime
#  hidden_by_administration_at                        :datetime
#  hidden_by_reason                                   :string
#  hidden_by_user_at                                  :datetime
#  identity_updated_at                                :datetime
#  last_avis_updated_at                               :datetime
#  last_champ_private_updated_at                      :datetime
#  last_champ_updated_at                              :datetime
#  last_commentaire_updated_at                        :datetime
#  motivation                                         :text
#  private_search_terms                               :text
#  processed_at                                       :datetime
#  search_terms                                       :text
#  state                                              :string
#  termine_close_to_expiration_notice_sent_at         :datetime
#  created_at                                         :datetime
#  updated_at                                         :datetime
#  dossier_transfer_id                                :bigint
#  groupe_instructeur_id                              :bigint
#  revision_id                                        :bigint
#  user_id                                            :integer
#
class Dossier < ApplicationRecord
  self.ignored_columns = [:en_construction_conservation_extension]
  include DossierFilteringConcern
  include DossierRebaseConcern

  enum state: {
    brouillon:       'brouillon',
    en_construction: 'en_construction',
    en_instruction:  'en_instruction',
    accepte:         'accepte',
    refuse:          'refuse',
    sans_suite:      'sans_suite'
  }

  EN_CONSTRUCTION_OU_INSTRUCTION = [states.fetch(:en_construction), states.fetch(:en_instruction)]
  TERMINE = [states.fetch(:accepte), states.fetch(:refuse), states.fetch(:sans_suite)]
  INSTRUCTION_COMMENCEE = TERMINE + [states.fetch(:en_instruction)]
  SOUMIS = EN_CONSTRUCTION_OU_INSTRUCTION + TERMINE

  REMAINING_DAYS_BEFORE_CLOSING = 2
  INTERVAL_BEFORE_CLOSING = "#{REMAINING_DAYS_BEFORE_CLOSING} days"
  REMAINING_WEEKS_BEFORE_EXPIRATION = 2
  INTERVAL_BEFORE_EXPIRATION = "#{REMAINING_WEEKS_BEFORE_EXPIRATION} weeks"
  MONTHS_AFTER_EXPIRATION = 1
  DAYS_AFTER_EXPIRATION = 5
  INTERVAL_EXPIRATION = "#{MONTHS_AFTER_EXPIRATION} month #{DAYS_AFTER_EXPIRATION} days"

  has_one :etablissement, dependent: :destroy
  has_one :individual, validate: false, dependent: :destroy
  has_one :attestation, dependent: :destroy

  # FIXME: some dossiers have more than one attestation
  has_many :attestations, dependent: :destroy

  has_one_attached :justificatif_motivation

  has_many :champs, -> { root.public_ordered }, inverse_of: false, dependent: :destroy
  has_many :champs_private, -> { root.private_ordered }, class_name: 'Champ', inverse_of: false, dependent: :destroy
  has_many :commentaires, inverse_of: :dossier, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :follows, -> { active }, inverse_of: :dossier
  has_many :previous_follows, -> { inactive }, class_name: 'Follow', inverse_of: :dossier
  has_many :followers_instructeurs, through: :follows, source: :instructeur
  has_many :previous_followers_instructeurs, -> { distinct }, through: :previous_follows, source: :instructeur
  has_many :avis, inverse_of: :dossier, dependent: :destroy
  has_many :experts, through: :avis
  has_many :traitements, -> { order(:processed_at) }, inverse_of: :dossier, dependent: :destroy do
    def passer_en_construction(instructeur: nil, processed_at: Time.zone.now)
      build(state: Dossier.states.fetch(:en_construction),
        instructeur_email: instructeur&.email,
        processed_at: processed_at)
    end

    def passer_en_instruction(instructeur: nil, processed_at: Time.zone.now)
      build(state: Dossier.states.fetch(:en_instruction),
        instructeur_email: instructeur&.email,
        processed_at: processed_at)
    end

    def accepter_automatiquement(processed_at: Time.zone.now)
      build(state: Dossier.states.fetch(:accepte),
        processed_at: processed_at)
    end

    def accepter(motivation: nil, instructeur: nil, processed_at: Time.zone.now)
      build(state: Dossier.states.fetch(:accepte),
        instructeur_email: instructeur&.email,
        motivation: motivation,
        processed_at: processed_at)
    end

    def refuser(motivation: nil, instructeur: nil, processed_at: Time.zone.now)
      build(state: Dossier.states.fetch(:refuse),
        instructeur_email: instructeur&.email,
        motivation: motivation,
        processed_at: processed_at)
    end

    def classer_sans_suite(motivation: nil, instructeur: nil, processed_at: Time.zone.now)
      build(state: Dossier.states.fetch(:sans_suite),
        instructeur_email: instructeur&.email,
        motivation: motivation,
        processed_at: processed_at)
    end
  end
  has_one :traitement, -> { order(processed_at: :desc) }, inverse_of: false

  has_many :dossier_operation_logs, -> { order(:created_at) }, inverse_of: :dossier

  belongs_to :groupe_instructeur, optional: true
  belongs_to :revision, class_name: 'ProcedureRevision', optional: false
  belongs_to :user, optional: true
  has_one :france_connect_information, through: :user

  has_one :attestation_template, through: :revision
  has_one :procedure, through: :revision
  has_many :types_de_champ, through: :revision, source: :types_de_champ_public
  has_many :types_de_champ_private, through: :revision

  belongs_to :transfer, class_name: 'DossierTransfer', foreign_key: 'dossier_transfer_id', optional: true, inverse_of: :dossiers
  has_many :transfer_logs, class_name: 'DossierTransferLog', dependent: :destroy

  accepts_nested_attributes_for :champs
  accepts_nested_attributes_for :champs_private

  include AASM

  aasm whiny_persistence: true, column: :state, enum: true do
    state :brouillon, initial: true
    state :en_construction
    state :en_instruction
    state :accepte
    state :refuse
    state :sans_suite

    event :passer_en_construction, after: :after_passer_en_construction do
      transitions from: :brouillon, to: :en_construction
    end

    event :passer_en_instruction, after: :after_passer_en_instruction do
      transitions from: :en_construction, to: :en_instruction
    end

    event :passer_automatiquement_en_instruction, after: :after_passer_automatiquement_en_instruction do
      transitions from: :en_construction, to: :en_instruction
    end

    event :repasser_en_construction, after: :after_repasser_en_construction do
      transitions from: :en_instruction, to: :en_construction
    end

    event :accepter, after: :after_accepter do
      transitions from: :en_instruction, to: :accepte, guard: :can_terminer?
    end

    event :accepter_automatiquement, after: :after_accepter_automatiquement do
      transitions from: :en_construction, to: :accepte, guard: :can_terminer?
    end

    event :refuser, after: :after_refuser do
      transitions from: :en_instruction, to: :refuse, guard: :can_terminer?
    end

    event :classer_sans_suite, after: :after_classer_sans_suite do
      transitions from: :en_instruction, to: :sans_suite, guard: :can_terminer?
    end

    event :repasser_en_instruction, after: :after_repasser_en_instruction do
      transitions from: :refuse, to: :en_instruction, guard: :can_repasser_en_instruction?
      transitions from: :sans_suite, to: :en_instruction, guard: :can_repasser_en_instruction?
      transitions from: :accepte, to: :en_instruction, guard: :can_repasser_en_instruction?
    end
  end

  scope :state_brouillon,                      -> { where(state: states.fetch(:brouillon)) }
  scope :state_not_brouillon,                  -> { where.not(state: states.fetch(:brouillon)) }
  scope :state_en_construction,                -> { where(state: states.fetch(:en_construction)) }
  scope :state_not_en_construction,            -> { where.not(state: states.fetch(:en_construction)) }
  scope :state_en_instruction,                 -> { where(state: states.fetch(:en_instruction)) }
  scope :state_en_construction_ou_instruction, -> { where(state: EN_CONSTRUCTION_OU_INSTRUCTION) }
  scope :state_instruction_commencee,          -> { where(state: INSTRUCTION_COMMENCEE) }
  scope :state_termine,                        -> { where(state: TERMINE) }
  scope :state_not_termine,                    -> { where.not(state: TERMINE) }

  scope :archived,      -> { where(archived: true) }
  scope :not_archived,  -> { where(archived: false) }
  scope :hidden_by_user, -> { where.not(hidden_by_user_at: nil) }
  scope :hidden_by_administration, -> { where.not(hidden_by_administration_at: nil) }
  scope :visible_by_user, -> { where(for_procedure_preview: false).or(where(for_procedure_preview: nil)).where(hidden_by_user_at: nil) }
  scope :visible_by_administration, -> {
    state_not_brouillon
      .where(hidden_by_administration_at: nil)
      .merge(visible_by_user.or(state_not_en_construction))
  }
  scope :visible_by_user_or_administration, -> { visible_by_user.or(visible_by_administration) }
  scope :for_procedure_preview, -> { where(for_procedure_preview: true) }

  scope :order_by_updated_at, -> (order = :desc) { order(updated_at: order) }
  scope :order_by_created_at, -> (order = :asc) { order(depose_at: order, created_at: order, id: order) }
  scope :updated_since,       -> (since) { where('dossiers.updated_at >= ?', since) }
  scope :created_since,       -> (since) { where('dossiers.depose_at >= ?', since) }

  scope :with_type_de_champ, -> (stable_id) {
    joins('INNER JOIN champs ON champs.dossier_id = dossiers.id INNER JOIN types_de_champ ON types_de_champ.id = champs.type_de_champ_id')
      .where('types_de_champ.private = FALSE AND types_de_champ.stable_id = ?', stable_id)
  }

  scope :with_type_de_champ_private, -> (stable_id) {
    joins('INNER JOIN champs ON champs.dossier_id = dossiers.id INNER JOIN types_de_champ ON types_de_champ.id = champs.type_de_champ_id')
      .where('types_de_champ.private = TRUE AND types_de_champ.stable_id = ?', stable_id)
  }

  scope :all_state,                   -> { not_archived.state_not_brouillon }
  scope :en_construction,             -> { not_archived.state_en_construction }
  scope :en_instruction,              -> { not_archived.state_en_instruction }
  scope :termine,                     -> { not_archived.state_termine }

  scope :processed_in_month, -> (date) do
    date = date.to_datetime
    state_termine
      .where(processed_at: date.beginning_of_month..date.end_of_month)
  end
  scope :ordered_for_export, -> {
    order(depose_at: 'asc')
  }
  scope :en_cours,                    -> { not_archived.state_en_construction_ou_instruction }
  scope :without_followers,           -> { left_outer_joins(:follows).where(follows: { id: nil }) }
  scope :with_champs, -> {
    includes(champs: [
      :type_de_champ,
      :geo_areas,
      piece_justificative_file_attachment: :blob,
      champs: [:type_de_champ, piece_justificative_file_attachment: :blob]
    ])
  }
  scope :with_annotations, -> {
    includes(champs_private: [
      :type_de_champ,
      :geo_areas,
      piece_justificative_file_attachment: :blob,
      champs: [:type_de_champ, piece_justificative_file_attachment: :blob]
    ])
  }
  scope :for_api, -> {
    with_champs
      .with_annotations
      .includes(commentaires: { piece_jointe_attachment: :blob },
        justificatif_motivation_attachment: :blob,
        attestation: [],
        avis: { piece_justificative_file_attachment: :blob },
        traitement: [],
        etablissement: [],
        individual: [],
        user: [])
  }

  scope :with_notifiable_procedure, -> (opts = { notify_on_closed: false }) do
    states = opts[:notify_on_closed] ? [:publiee, :close, :depubliee] : [:publiee, :depubliee]
    joins(:procedure)
      .where(procedures: { aasm_state: states })
      .where.not(user_id: nil)
  end

  scope :interval_brouillon_close_to_expiration, -> do
    state_brouillon
      .visible_by_user
      .where("dossiers.created_at + dossiers.conservation_extension + (procedures.duree_conservation_dossiers_dans_ds * INTERVAL '1 month') - INTERVAL :expires_in < :now", { now: Time.zone.now, expires_in: INTERVAL_BEFORE_EXPIRATION })
  end
  scope :interval_en_construction_close_to_expiration, -> do
    state_en_construction
      .visible_by_user_or_administration
      .where("dossiers.en_construction_at + dossiers.conservation_extension + (procedures.duree_conservation_dossiers_dans_ds * INTERVAL '1 month') - INTERVAL :expires_in < :now", { now: Time.zone.now, expires_in: INTERVAL_BEFORE_EXPIRATION })
  end
  scope :interval_termine_close_to_expiration, -> do
    state_termine
      .visible_by_user_or_administration
      .where(procedures: { procedure_expires_when_termine_enabled: true })
      .where("dossiers.processed_at + dossiers.conservation_extension + (procedures.duree_conservation_dossiers_dans_ds * INTERVAL '1 month') - INTERVAL :expires_in < :now", { now: Time.zone.now, expires_in: INTERVAL_BEFORE_EXPIRATION })
  end

  scope :brouillon_close_to_expiration, -> do
    joins(:procedure).interval_brouillon_close_to_expiration
  end
  scope :en_construction_close_to_expiration, -> do
    joins(:procedure).interval_en_construction_close_to_expiration
  end
  scope :termine_close_to_expiration, -> do
    joins(:procedure).interval_termine_close_to_expiration
  end

  scope :close_to_expiration, -> do
    joins(:procedure).scoping do
      interval_brouillon_close_to_expiration
        .or(interval_en_construction_close_to_expiration)
        .or(interval_termine_close_to_expiration)
    end
  end

  scope :termine_or_en_construction_close_to_expiration, -> do
    joins(:procedure).scoping do
      interval_en_construction_close_to_expiration
        .or(interval_termine_close_to_expiration)
    end
  end

  scope :brouillon_expired, -> do
    state_brouillon
      .visible_by_user
      .where("brouillon_close_to_expiration_notice_sent_at + INTERVAL :expires_in < :now", { now: Time.zone.now, expires_in: INTERVAL_EXPIRATION })
  end
  scope :en_construction_expired, -> do
    state_en_construction
      .visible_by_user_or_administration
      .where("en_construction_close_to_expiration_notice_sent_at + INTERVAL :expires_in < :now", { now: Time.zone.now, expires_in: INTERVAL_EXPIRATION })
  end
  scope :termine_expired, -> do
    state_termine
      .visible_by_user_or_administration
      .where("termine_close_to_expiration_notice_sent_at + INTERVAL :expires_in < :now", { now: Time.zone.now, expires_in: INTERVAL_EXPIRATION })
  end

  scope :without_brouillon_expiration_notice_sent, -> { where(brouillon_close_to_expiration_notice_sent_at: nil) }
  scope :without_en_construction_expiration_notice_sent, -> { where(en_construction_close_to_expiration_notice_sent_at: nil) }
  scope :without_termine_expiration_notice_sent, -> { where(termine_close_to_expiration_notice_sent_at: nil) }

  scope :deleted_by_user_expired, -> { where('dossiers.hidden_by_user_at < ?', 1.week.ago) }
  scope :deleted_by_administration_expired, -> { where('dossiers.hidden_by_administration_at < ?', 1.week.ago) }
  scope :en_brouillon_expired_to_delete, -> { state_brouillon.deleted_by_user_expired }
  scope :en_construction_expired_to_delete, -> { state_en_construction.deleted_by_user_expired }
  scope :termine_expired_to_delete, -> { state_termine.deleted_by_user_expired.deleted_by_administration_expired }

  scope :brouillon_near_procedure_closing_date, -> do
    # select users who have submitted dossier for the given 'procedures.id'
    users_who_submitted =
      state_not_brouillon
        .visible_by_user
        .joins(:revision)
        .where("procedure_revisions.procedure_id = procedures.id")
        .select(:user_id)
    # select dossier in brouillon where procedure closes in two days and for which the user has not submitted a Dossier
    state_brouillon
      .visible_by_user
      .with_notifiable_procedure
      .where("procedures.auto_archive_on - INTERVAL :before_closing = :now", { now: Time.zone.today, before_closing: INTERVAL_BEFORE_CLOSING })
      .where.not(user: users_who_submitted)
  end

  scope :for_api_v2, -> { includes(revision: [:attestation_template, procedure: [:administrateurs]], etablissement: [], individual: [], traitement: []) }

  scope :with_notifications, -> do
    joins(:follows)
      .where('last_champ_updated_at > follows.demande_seen_at' \
      ' OR identity_updated_at > follows.demande_seen_at' \
      ' OR groupe_instructeur_updated_at > follows.demande_seen_at' \
      ' OR last_champ_private_updated_at > follows.annotations_privees_seen_at' \
      ' OR last_avis_updated_at > follows.avis_seen_at' \
      ' OR last_commentaire_updated_at > follows.messagerie_seen_at')
      .distinct
  end

  scope :by_statut, -> (instructeur, statut = 'tous') do
    case statut
    when 'a-suivre'
      visible_by_administration
        .without_followers
        .en_cours
    when 'suivis'
      instructeur
        .followed_dossiers
        .en_cours
        .merge(visible_by_administration)
    when 'traites'
      visible_by_administration.termine
    when 'tous'
      visible_by_administration.all_state
    when 'supprimes_recemment'
      hidden_by_administration.termine
    when 'archives'
      visible_by_administration.archived
    when 'expirant'
      visible_by_administration.termine_or_en_construction_close_to_expiration
    end
  end

  accepts_nested_attributes_for :individual

  delegate :siret, :siren, to: :etablissement, allow_nil: true
  delegate :france_connect_information, to: :user, allow_nil: true

  before_save :build_default_champs, if: Proc.new { revision_id_was.nil? }
  before_save :update_search_terms

  after_save :send_web_hook
  after_create_commit :send_draft_notification_email

  validates :user, presence: true, if: -> { deleted_user_email_never_send.nil? }
  validates :individual, presence: true, if: -> { revision.procedure.for_individual? }
  validates :groupe_instructeur, presence: true, if: -> { !brouillon? }

  def types_de_champ_public
    types_de_champ
  end

  def self.downloadable_sorted_batch
    DossierPreloader.new(includes(
      :user,
      :individual,
      :followers_instructeurs,
      :traitement,
      :groupe_instructeur,
      :etablissement,
      procedure: [:groupe_instructeurs],
      avis: [:claimant, :expert]
    ).ordered_for_export).in_batches
  end

  def user_deleted?
    persisted? && user_id.nil?
  end

  def user_email_for(use)
    if user_deleted?
      if use == :display
        deleted_user_email_never_send
      else
        raise "Can not send email to discarded user"
      end
    else
      user.email
    end
  end

  def motivation
    if termine?
      traitement&.motivation || read_attribute(:motivation)
    end
  end

  def update_search_terms
    self.search_terms = [
      user&.email,
      *champs.flat_map(&:search_terms),
      *etablissement&.search_terms,
      individual&.nom,
      individual&.prenom
    ].compact.join(' ')
    self.private_search_terms = champs_private.flat_map(&:search_terms).compact.join(' ')
  end

  def build_default_champs
    revision.build_champs.each do |champ|
      champs << champ
    end
    revision.build_champs_private.each do |champ|
      champs_private << champ
    end
  end

  def build_default_individual
    if procedure.for_individual? && individual.blank?
      self.individual = if france_connect_information.present?
        Individual.from_france_connect(france_connect_information)
      else
        Individual.new
      end
    end
  end

  def en_construction_ou_instruction?
    EN_CONSTRUCTION_OU_INSTRUCTION.include?(state)
  end

  def termine?
    TERMINE.include?(state)
  end

  def instruction_commencee?
    INSTRUCTION_COMMENCEE.include?(state)
  end

  def reset!
    etablissement.destroy

    update_columns(autorisation_donnees: false)
  end

  def read_only?
    en_instruction? || accepte? || refuse? || sans_suite? || procedure.discarded? || procedure.close? && brouillon?
  end

  def can_transition_to_en_construction?
    brouillon? && procedure.dossier_can_transition_to_en_construction? && !for_procedure_preview?
  end

  def can_terminer?
    return false if etablissement&.as_degraded_mode?

    true
  end

  def can_repasser_en_instruction?
    termine? && !user_deleted?
  end

  def can_be_updated_by_user?
    brouillon? || en_construction?
  end

  def can_be_deleted_by_user?
    brouillon? || en_construction? || termine?
  end

  def can_be_deleted_by_administration?(reason)
    termine? || reason == :procedure_removed
  end

  def messagerie_available?
    visible_by_administration? && !hidden_by_user? && !user_deleted? && !archived
  end

  def expirable?
    [
      brouillon?,
      en_construction?,
      termine? && procedure.procedure_expires_when_termine_enabled
    ].any?
  end

  def expiration_date_reference
    if brouillon?
      created_at
    elsif en_construction?
      en_construction_at
    elsif termine?
      processed_at
    else
      fail "expiration_date_reference should not be called in state #{self.state}"
    end
  end

  def expiration_date_with_extention
    [
      expiration_date_reference,
      conservation_extension,
      procedure.duree_conservation_dossiers_dans_ds.months
    ].sum
  end

  def expiration_notification_date
    expiration_date_with_extention - REMAINING_WEEKS_BEFORE_EXPIRATION.weeks
  end

  def close_to_expiration?
    return false if en_instruction?
    expiration_notification_date < Time.zone.now
  end

  def after_notification_expiration_date
    if brouillon? && brouillon_close_to_expiration_notice_sent_at.present?
      brouillon_close_to_expiration_notice_sent_at + duration_after_notice
    elsif en_construction? && en_construction_close_to_expiration_notice_sent_at.present?
      en_construction_close_to_expiration_notice_sent_at + duration_after_notice
    elsif termine? && termine_close_to_expiration_notice_sent_at.present?
      termine_close_to_expiration_notice_sent_at + duration_after_notice
    end
  end

  def expiration_date
    after_notification_expiration_date.presence || expiration_date_with_extention
  end

  def duration_after_notice
    MONTHS_AFTER_EXPIRATION.month + DAYS_AFTER_EXPIRATION.days
  end

  def expiration_can_be_extended?
    brouillon? || en_construction?
  end

  def extend_conservation(conservation_extension)
    update(conservation_extension: self.conservation_extension + conservation_extension,
      brouillon_close_to_expiration_notice_sent_at: nil,
      en_construction_close_to_expiration_notice_sent_at: nil,
      termine_close_to_expiration_notice_sent_at: nil)
  end

  def show_procedure_state_warning?
    procedure.discarded? || (brouillon? && !procedure.dossier_can_transition_to_en_construction?)
  end

  def show_groupe_instructeur_details?
    procedure.routee? && groupe_instructeur.present? && (!procedure.feature_enabled?(:procedure_routage_api) || !defaut_groupe_instructeur?)
  end

  def show_groupe_instructeur_selector?
    procedure.routee? && !procedure.feature_enabled?(:procedure_routage_api) && procedure.groupe_instructeurs.size > 1
  end

  def assign_to_groupe_instructeur(groupe_instructeur, author = nil)
    if (groupe_instructeur.nil? || groupe_instructeur.procedure == procedure) && self.groupe_instructeur != groupe_instructeur
      if update(groupe_instructeur: groupe_instructeur, groupe_instructeur_updated_at: Time.zone.now)
        unfollow_stale_instructeurs

        if author.present?
          log_dossier_operation(author, :changer_groupe_instructeur, self)
        end

        true
      end
    else
      false
    end
  end

  def archiver!(author)
    update!(archived: true)
    log_dossier_operation(author, :archiver)
  end

  def desarchiver!(author)
    update!(archived: false)
    log_dossier_operation(author, :desarchiver)
  end

  def text_summary
    if brouillon?
      parts = [
        "Dossier en brouillon répondant à la démarche ",
        procedure.libelle,
        " gérée par l'organisme ",
        procedure.organisation_name
      ]
    else
      parts = [
        "Dossier déposé le ",
        depose_at.strftime("%d/%m/%Y"),
        " sur la démarche ",
        procedure.libelle,
        " gérée par l'organisme ",
        procedure.organisation_name
      ]
    end

    parts.join
  end

  def duree_totale_conservation_in_months
    procedure.duree_conservation_dossiers_dans_ds + (conservation_extension / 1.month.to_i)
  end

  def avis_for_instructeur(instructeur)
    if instructeur.dossiers.include?(self)
      avis.order(created_at: :asc)
    else
      avis
        .where(confidentiel: false)
        .or(avis.where(claimant: instructeur))
        .order(created_at: :asc)
    end
  end

  def avis_for_expert(expert)
    Avis
      .where(dossier_id: id, confidentiel: false)
      .or(Avis.where(id: expert.avis, dossier_id: id))
      .order(created_at: :asc)
  end

  def owner_name
    if etablissement.present?
      etablissement.entreprise_raison_sociale
    elsif individual.present?
      "#{individual.nom} #{individual.prenom}"
    end
  end

  def log_operations?
    !procedure.brouillon? && !brouillon?
  end

  def hidden_by_user?
    hidden_by_user_at.present?
  end

  def hidden_by_administration?
    hidden_by_administration_at.present?
  end

  def hidden_for_administration?
    hidden_by_administration? || (hidden_by_user? && en_construction?) || brouillon?
  end

  def visible_by_administration?
    !hidden_for_administration?
  end

  def hidden_for_administration_and_user?
    hidden_for_administration? && hidden_by_user?
  end

  def expose_legacy_carto_api?
    procedure.expose_legacy_carto_api?
  end

  def geo_position
    if etablissement.present?
      point = Geocoder.search(etablissement.geo_adresse).first
    end

    lon = Champs::CarteChamp::DEFAULT_LON.to_s
    lat = Champs::CarteChamp::DEFAULT_LAT.to_s
    zoom = "13"

    if point.present?
      lat, lon = point.coordinates.map(&:to_s)
    end

    { lon: lon, lat: lat, zoom: zoom }
  end

  def unspecified_attestation_champs
    if attestation_template&.activated?
      attestation_template.unspecified_champs_for_dossier(self)
    else
      []
    end
  end

  def build_attestation
    if attestation_template&.activated?
      attestation_template.attestation_for(self)
    end
  end

  def expired_keep_track_and_destroy!
    transaction do
      DeletedDossier.create_from_dossier(self, :expired)
      dossier_operation_logs.destroy_all
      log_automatic_dossier_operation(:supprimer, self)
      destroy!
    end
    true
  rescue
    false
  end

  def author_is_user(author)
    author.is_a?(User)
  end

  def author_is_administration(author)
    author.is_a?(Instructeur) || author.is_a?(Administrateur) || author.is_a?(SuperAdmin)
  end

  def hide_and_keep_track!(author, reason)
    transaction do
      if author_is_administration(author) && can_be_deleted_by_administration?(reason)
        update(hidden_by_administration_at: Time.zone.now, hidden_by_reason: reason)
      elsif author_is_user(author) && can_be_deleted_by_user?
        update(hidden_by_user_at: Time.zone.now, dossier_transfer_id: nil, hidden_by_reason: reason)
      else
        raise "Unauthorized dossier hide attempt Dossier##{id} by #{author} for reason #{reason}"
      end

      log_dossier_operation(author, :supprimer, self)
    end

    if en_construction? && !hidden_by_administration?
      administration_emails = followers_instructeurs.present? ? followers_instructeurs.map(&:email) : procedure.administrateurs.map(&:email)
      administration_emails.each do |email|
        DossierMailer.notify_en_construction_deletion_to_administration(self, email).deliver_later
      end
    end
  end

  def restore(author)
    transaction do
      if author_is_administration(author)
        update(hidden_by_administration_at: nil)
      elsif author_is_user(author)
        update(hidden_by_user_at: nil)
      end

      if !hidden_by_user? && !hidden_by_administration?
        update(hidden_by_reason: nil)
      end

      log_dossier_operation(author, :restaurer, self)
    end
  end

  def attestation_activated?
    termine? && attestation_template&.activated?
  end

  def after_passer_en_construction
    self.conservation_extension = 0.days
    self.depose_at = self.en_construction_at = self.traitements
      .passer_en_construction
      .processed_at
    save!
  end

  def after_passer_en_instruction(h)
    instructeur = h[:instructeur]
    disable_notification = h.fetch(:disable_notification, false)

    instructeur.follow(self)

    self.en_construction_close_to_expiration_notice_sent_at = nil
    self.conservation_extension = 0.days
    self.en_instruction_at = self.traitements
      .passer_en_instruction(instructeur: instructeur)
      .processed_at
    save!

    if !procedure.declarative_accepte? && !disable_notification
      NotificationMailer.send_en_instruction_notification(self).deliver_later
    end
    log_dossier_operation(instructeur, :passer_en_instruction)
  end

  def after_passer_automatiquement_en_instruction
    self.en_construction_close_to_expiration_notice_sent_at = nil
    self.conservation_extension = 0.days
    self.en_instruction_at = self.declarative_triggered_at = self.traitements
      .passer_en_instruction
      .processed_at
    save!
    log_automatic_dossier_operation(:passer_en_instruction)
  end

  def after_repasser_en_construction(instructeur)
    create_missing_traitemets

    self.en_construction_close_to_expiration_notice_sent_at = nil
    self.conservation_extension = 0.days
    self.en_construction_at = self.traitements
      .passer_en_construction(instructeur: instructeur)
      .processed_at
    save!
    log_dossier_operation(instructeur, :repasser_en_construction)
  end

  def after_repasser_en_instruction(h)
    instructeur = h[:instructeur]
    disable_notification = h.fetch(:disable_notification, false)

    create_missing_traitemets

    self.hidden_by_user_at = nil
    self.archived = false
    self.termine_close_to_expiration_notice_sent_at = nil
    self.conservation_extension = 0.days
    self.en_instruction_at = self.traitements
      .passer_en_instruction(instructeur: instructeur)
      .processed_at
    attestation&.destroy

    save!
    if !disable_notification
      DossierMailer.notify_revert_to_instruction(self).deliver_later
    end
    log_dossier_operation(instructeur, :repasser_en_instruction)
  end

  def after_accepter(h)
    instructeur = h[:instructeur]
    motivation = h[:motivation]
    justificatif = h[:justificatif]
    disable_notification = h.fetch(:disable_notification, false)

    self.processed_at = self.traitements
      .accepter(motivation: motivation, instructeur: instructeur)
      .processed_at
    save!

    if justificatif
      self.justificatif_motivation.attach(justificatif)
    end

    if attestation.nil?
      self.attestation = build_attestation
    end

    save!
    remove_titres_identite!
    if !disable_notification
      NotificationMailer.send_accepte_notification(self).deliver_later
    end
    send_dossier_decision_to_experts(self)
    log_dossier_operation(instructeur, :accepter, self)
  end

  def after_accepter_automatiquement
    self.processed_at = self.en_instruction_at = self.declarative_triggered_at = self.traitements
      .accepter_automatiquement
      .processed_at
    save!

    if attestation.nil?
      self.attestation = build_attestation
    end

    save!
    remove_titres_identite!
    NotificationMailer.send_accepte_notification(self).deliver_later
    log_automatic_dossier_operation(:accepter, self)
  end

  def after_refuser(h)
    instructeur = h[:instructeur]
    motivation = h[:motivation]
    justificatif = h[:justificatif]
    disable_notification = h.fetch(:disable_notification, false)

    self.processed_at = self.traitements
      .refuser(motivation: motivation, instructeur: instructeur)
      .processed_at
    save!

    if justificatif
      self.justificatif_motivation.attach(justificatif)
    end

    save!
    remove_titres_identite!
    if !disable_notification
      NotificationMailer.send_refuse_notification(self).deliver_later
    end
    send_dossier_decision_to_experts(self)
    log_dossier_operation(instructeur, :refuser, self)
  end

  def after_classer_sans_suite(h)
    instructeur = h[:instructeur]
    motivation = h[:motivation]
    justificatif = h[:justificatif]
    disable_notification = h.fetch(:disable_notification, false)

    self.processed_at = self.traitements
      .classer_sans_suite(motivation: motivation, instructeur: instructeur)
      .processed_at
    save!

    if justificatif
      self.justificatif_motivation.attach(justificatif)
    end

    save!
    remove_titres_identite!
    if !disable_notification
      NotificationMailer.send_sans_suite_notification(self).deliver_later
    end
    send_dossier_decision_to_experts(self)
    log_dossier_operation(instructeur, :classer_sans_suite, self)
  end

  def remove_titres_identite!
    champs.filter(&:titre_identite?).map(&:piece_justificative_file).each(&:purge_later)
  end

  def check_mandatory_and_visible_champs
    (champs + champs.filter(&:block?).filter(&:visible?).flat_map(&:champs))
      .filter(&:visible?)
      .filter(&:mandatory_blank?)
      .map do |champ|
        "Le champ #{champ.libelle.truncate(200)} doit être rempli."
      end
  end

  def log_modifier_annotations!(instructeur)
    champs_private.filter(&:value_previously_changed?).each do |champ|
      log_dossier_operation(instructeur, :modifier_annotation, champ)
    end
  end

  def log_modifier_annotation!(champ, instructeur)
    log_dossier_operation(instructeur, :modifier_annotation, champ)
  end

  def demander_un_avis!(avis)
    log_dossier_operation(avis.claimant, :demander_un_avis, avis)
  end

  def spreadsheet_columns_csv(types_de_champ:)
    spreadsheet_columns(with_etablissement: true, types_de_champ: types_de_champ)
  end

  def spreadsheet_columns_xlsx(types_de_champ:)
    spreadsheet_columns(types_de_champ: types_de_champ)
  end

  def spreadsheet_columns_ods(types_de_champ:)
    spreadsheet_columns(types_de_champ: types_de_champ)
  end

  def spreadsheet_columns(with_etablissement: false, types_de_champ:)
    columns = [
      ['ID', id.to_s],
      ['Email', user_email_for(:display)]
    ]

    if procedure.for_individual?
      columns += [
        ['Civilité', individual&.gender],
        ['Nom', individual&.nom],
        ['Prénom', individual&.prenom]
      ]
      if procedure.ask_birthday
        columns += [['Date de naissance', individual&.birthdate]]
      end
    elsif with_etablissement
      columns += [
        ['Établissement SIRET', etablissement&.siret],
        ['Établissement siège social', etablissement&.siege_social],
        ['Établissement NAF', etablissement&.naf],
        ['Établissement libellé NAF', etablissement&.libelle_naf],
        ['Établissement Adresse', etablissement&.adresse],
        ['Établissement numero voie', etablissement&.numero_voie],
        ['Établissement type voie', etablissement&.type_voie],
        ['Établissement nom voie', etablissement&.nom_voie],
        ['Établissement complément adresse', etablissement&.complement_adresse],
        ['Établissement code postal', etablissement&.code_postal],
        ['Établissement localité', etablissement&.localite],
        ['Établissement code INSEE localité', etablissement&.code_insee_localite],
        ['Entreprise SIREN', etablissement&.entreprise_siren],
        ['Entreprise capital social', etablissement&.entreprise_capital_social],
        ['Entreprise numero TVA intracommunautaire', etablissement&.entreprise_numero_tva_intracommunautaire],
        ['Entreprise forme juridique', etablissement&.entreprise_forme_juridique],
        ['Entreprise forme juridique code', etablissement&.entreprise_forme_juridique_code],
        ['Entreprise nom commercial', etablissement&.entreprise_nom_commercial],
        ['Entreprise raison sociale', etablissement&.entreprise_raison_sociale],
        ['Entreprise SIRET siège social', etablissement&.entreprise_siret_siege_social],
        ['Entreprise code effectif entreprise', etablissement&.entreprise_code_effectif_entreprise],
        ['Entreprise date de création', etablissement&.entreprise_date_creation],
        ['Entreprise état administratif', etablissement&.entreprise_etat_administratif],
        ['Entreprise nom', etablissement&.entreprise_nom],
        ['Entreprise prénom', etablissement&.entreprise_prenom],
        ['Association RNA', etablissement&.association_rna],
        ['Association titre', etablissement&.association_titre],
        ['Association objet', etablissement&.association_objet],
        ['Association date de création', etablissement&.association_date_creation],
        ['Association date de déclaration', etablissement&.association_date_declaration],
        ['Association date de publication', etablissement&.association_date_publication]
      ]
    else
      columns << ['Entreprise raison sociale', etablissement&.entreprise_raison_sociale]
    end

    columns += [
      ['Archivé', :archived],
      ['État du dossier', Dossier.human_attribute_name("state.#{state}")],
      ['Dernière mise à jour le', :updated_at],
      ['Déposé le', :depose_at],
      ['Passé en instruction le', :en_instruction_at],
      ['Traité le', :processed_at],
      ['Motivation de la décision', :motivation],
      ['Instructeurs', followers_instructeurs.map(&:email).join(' ')]
    ]

    if procedure.routee?
      columns << ['Groupe instructeur', groupe_instructeur.label]
    end
    columns + self.class.champs_for_export(champs + champs_private, types_de_champ)
  end

  # Get all the champs values for the types de champ in the final list.
  # Dossier might not have corresponding champ – display nil.
  # To do so, we build a virtual champ when there is no value so we can call for_export with all indexes
  def self.champs_for_export(champs, types_de_champ)
    types_de_champ.flat_map do |type_de_champ|
      champ = champs.find { |champ| champ.stable_id == type_de_champ.stable_id }

      exported_values = if champ.nil? || !champ.visible?
        # some champs export multiple columns
        # ex: commune.for_export => [commune, insee, departement]
        # so we build a fake champ to have the right export
        type_de_champ.champ.build.for_export
      else
        champ.for_export
      end

      # nil => [nil]
      # text => [text]
      # [commune, insee, departement] => [commune, insee, departement]
      wrapped_exported_values = [exported_values].flatten

      wrapped_exported_values.map.with_index do |champ_value, index|
        [type_de_champ.libelle_for_export(index), champ_value]
      end
    end
  end

  def linked_dossiers_for(instructeur_or_expert)
    dossier_ids = champs.filter(&:dossier_link?).filter_map(&:value)
    instructeur_or_expert.dossiers.where(id: dossier_ids)
  end

  def hash_for_deletion_mail
    { id: self.id, procedure_libelle: self.procedure.libelle }
  end

  def geo_data?
    geo_areas.present?
  end

  def to_feature_collection
    {
      type: 'FeatureCollection',
      id: id,
      bbox: bounding_box,
      features: geo_areas.map(&:to_feature)
    }
  end

  def log_api_entreprise_job_exception(exception)
    exceptions = self.api_entreprise_job_exceptions ||= []
    exceptions << exception.inspect
    update_column(:api_entreprise_job_exceptions, exceptions)
  end

  def user_locale
    user&.locale || I18n.default_locale
  end

  def purge_discarded
    transaction do
      DeletedDossier.create_from_dossier(self, hidden_by_reason)
      dossier_operation_logs.not_deletion.destroy_all
      destroy
    end
  end

  def self.purge_discarded
    en_brouillon_expired_to_delete.find_each(&:purge_discarded)
    en_construction_expired_to_delete.find_each(&:purge_discarded)
    termine_expired_to_delete.find_each(&:purge_discarded)
  end

  def sections_for(champ)
    @sections = Hash.new do |hash, parent|
      case parent
      when :public
        hash[parent] = champs.filter(&:header_section?)
      when :private
        hash[parent] = champs_private.filter(&:header_section?)
      else
        hash[parent] = parent.champs.filter(&:header_section?)
      end
    end
    @sections[champ.parent || (champ.public? ? :public : :private)]
  end

  private

  def create_missing_traitemets
    if en_construction_at.present? && traitements.en_construction.empty?
      self.traitements.passer_en_construction(processed_at: en_construction_at)
      self.depose_at ||= en_construction_at
    end
    if en_instruction_at.present? && traitements.en_instruction.empty?
      self.traitements.passer_en_instruction(processed_at: en_instruction_at)
    end
  end

  def deleted_dossier
    @deleted_dossier ||= DeletedDossier.find_by(dossier_id: id)
  end

  def defaut_groupe_instructeur?
    groupe_instructeur == procedure.defaut_groupe_instructeur
  end

  def geo_areas
    champs.flat_map(&:geo_areas) + champs_private.flat_map(&:geo_areas)
  end

  def bounding_box
    factory = RGeo::Geographic.simple_mercator_factory
    bounding_box = RGeo::Cartesian::BoundingBox.new(factory)

    geo_areas.filter_map(&:rgeo_geometry).each do |geometry|
      bounding_box.add(geometry)
    end

    [bounding_box.max_point, bounding_box.min_point].compact.flat_map(&:coordinates)
  end

  def log_dossier_operation(author, operation, subject = nil)
    if log_operations?
      DossierOperationLog.create_and_serialize(
        dossier: self,
        operation: DossierOperationLog.operations.fetch(operation),
        author: author,
        subject: subject
      )
    end
  end

  def log_automatic_dossier_operation(operation, subject = nil)
    if log_operations?
      DossierOperationLog.create_and_serialize(
        dossier: self,
        operation: DossierOperationLog.operations.fetch(operation),
        automatic_operation: true,
        subject: subject
      )
    end
  end

  def send_draft_notification_email
    if brouillon? && !procedure.declarative? && !for_procedure_preview?
      DossierMailer.notify_new_draft(self).deliver_later
    end
  end

  def send_web_hook
    if saved_change_to_state? && !brouillon? && procedure.web_hook_url.present?
      WebHookJob.perform_later(
        procedure.id,
        self.id,
        self.state,
        self.updated_at
      )
    end
  end

  def unfollow_stale_instructeurs
    followers_instructeurs.each do |instructeur|
      if instructeur.groupe_instructeurs.exclude?(groupe_instructeur)
        instructeur.unfollow(self)
        if visible_by_administration?
          DossierMailer.notify_groupe_instructeur_changed(instructeur, self).deliver_later
        end
      end
    end
  end

  def self.notify_draft_not_submitted
    brouillon_near_procedure_closing_date
      .includes(:user)
      .find_each do |dossier|
        DossierMailer.notify_brouillon_not_submitted(dossier).deliver_later
      end
  end

  def send_dossier_decision_to_experts(dossier)
    avis_experts_procedures_ids = Avis
      .joins(:experts_procedure)
      .where(dossier: dossier, experts_procedures: { allow_decision_access: true })
      .with_answer
      .distinct
      .pluck('avis.id, experts_procedures.id')

    # rubocop:disable Lint/UnusedBlockArgument
    avis = avis_experts_procedures_ids
      .uniq { |(avis_id, experts_procedures_id)| experts_procedures_id }
      .map { |(avis_id, _)| avis_id }
      .then { |avis_ids| Avis.find(avis_ids) }
    # rubocop:enable Lint/UnusedBlockArgument

    avis.each { |a| ExpertMailer.send_dossier_decision_v2(a).deliver_later }
  end
end
