class Dossier < ApplicationRecord
  include DossierFilteringConcern

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

  has_one :etablissement, dependent: :destroy
  has_one :individual, dependent: :destroy
  has_one :attestation, dependent: :destroy

  has_many :pieces_justificatives, dependent: :destroy
  has_one_attached :justificatif_motivation

  has_many :champs, -> { root.public_only.ordered }, dependent: :destroy
  has_many :champs_private, -> { root.private_only.ordered }, class_name: 'Champ', dependent: :destroy
  has_many :commentaires, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :follows
  has_many :followers_gestionnaires, through: :follows, source: :gestionnaire
  has_many :avis, dependent: :destroy

  has_many :dossier_operation_logs, dependent: :destroy

  belongs_to :procedure
  belongs_to :user

  accepts_nested_attributes_for :champs
  accepts_nested_attributes_for :champs_private

  default_scope { where(hidden_at: nil) }
  scope :state_brouillon,                      -> { where(state: states.fetch(:brouillon)) }
  scope :state_not_brouillon,                  -> { where.not(state: states.fetch(:brouillon)) }
  scope :state_en_construction,                -> { where(state: states.fetch(:en_construction)) }
  scope :state_en_instruction,                 -> { where(state: states.fetch(:en_instruction)) }
  scope :state_en_construction_ou_instruction, -> { where(state: EN_CONSTRUCTION_OU_INSTRUCTION) }
  scope :state_instruction_commencee,          -> { where(state: INSTRUCTION_COMMENCEE) }
  scope :state_termine,                        -> { where(state: TERMINE) }

  scope :archived,      -> { where(archived: true) }
  scope :not_archived,  -> { where(archived: false) }

  scope :order_by_updated_at, -> (order = :desc) { order(updated_at: order) }

  scope :all_state,                   -> { not_archived.state_not_brouillon }
  scope :en_construction,             -> { not_archived.state_en_construction }
  scope :en_instruction,              -> { not_archived.state_en_instruction }
  scope :termine,                     -> { not_archived.state_termine }
  scope :downloadable_sorted,         -> { state_not_brouillon.includes(:etablissement, :user, :individual, :followers_gestionnaires, champs: { etablissement: [], type_de_champ: :drop_down_list }, champs_private: { etablissement: [], type_de_champ: :drop_down_list }).order(en_construction_at: 'asc') }
  scope :en_cours,                    -> { not_archived.state_en_construction_ou_instruction }
  scope :without_followers,           -> { left_outer_joins(:follows).where(follows: { id: nil }) }
  scope :followed_by,                 -> (gestionnaire) { joins(:follows).where(follows: { gestionnaire: gestionnaire }) }
  scope :with_champs,                 -> { includes(champs: :type_de_champ) }
  scope :nearing_end_of_retention,    -> (duration = '1 month') { joins(:procedure).where("en_instruction_at + (duree_conservation_dossiers_dans_ds * interval '1 month') - now() < interval ?", duration) }
  scope :since,                       -> (since) { where('dossiers.en_construction_at >= ?', since) }
  scope :for_api, -> {
    includes(commentaires: [],
      champs: [
        :geo_areas,
        :etablissement,
        piece_justificative_file_attachment: :blob
      ],
      champs_private: [
        :geo_areas,
        :etablissement,
        piece_justificative_file_attachment: :blob
      ],
      pieces_justificatives: [],
      etablissement: [],
      individual: [],
      user: [])
  }

  accepts_nested_attributes_for :individual

  delegate :siret, :siren, to: :etablissement, allow_nil: true
  delegate :types_de_piece_justificative, to: :procedure
  delegate :types_de_champ, to: :procedure
  delegate :france_connect_information, to: :user

  before_validation :update_state_dates, if: -> { state_changed? }

  before_save :build_default_champs, if: Proc.new { procedure_id_changed? }
  before_save :build_default_individual, if: Proc.new { procedure.for_individual? }
  before_save :update_search_terms

  after_save :send_dossier_received
  after_save :send_web_hook
  after_create :send_draft_notification_email

  validates :user, presence: true

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

  def was_piece_justificative_uploaded_for_type_id?(type_id)
    pieces_justificatives.where(type_de_piece_justificative_id: type_id).count > 0
  end

  def retrieve_last_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).last
  end

  def retrieve_all_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).order(created_at: :DESC)
  end

  def build_default_champs
    procedure.build_champs.each do |champ|
      champs << champ
    end
    procedure.build_champs_private.each do |champ|
      champs_private << champ
    end
  end

  def build_default_individual
    if Individual.where(dossier_id: self.id).count == 0
      build_individual
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
    en_instruction? || accepte? || refuse? || sans_suite?
  end

  def can_transition_to_en_construction?
    !procedure.archivee? && brouillon?
  end

  def can_be_updated_by_user?
    brouillon? || en_construction?
  end

  def can_be_deleted_by_user?
    brouillon? || en_construction?
  end

  def messagerie_available?
    !brouillon? && !archived
  end

  def retention_end_date
    if instruction_commencee?
      en_instruction_at + procedure.duree_conservation_dossiers_dans_ds.months
    end
  end

  def retention_expired?
    instruction_commencee? && retention_end_date <= Time.zone.now
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
        en_construction_at.strftime("%d/%m/%Y"),
        " sur la démarche ",
        procedure.libelle,
        " gérée par l'organisme ",
        procedure.organisation_name
      ]
    end

    parts.join
  end

  def avis_for(gestionnaire)
    if gestionnaire.dossiers.include?(self)
      avis.order(created_at: :asc)
    else
      avis
        .where(confidentiel: false)
        .or(avis.where(claimant: gestionnaire))
        .or(avis.where(gestionnaire: gestionnaire))
        .order(created_at: :asc)
    end
  end

  def owner_name
    if etablissement.present?
      etablissement.entreprise_raison_sociale
    elsif individual.present?
      "#{individual.nom} #{individual.prenom}"
    end
  end

  def expose_legacy_carto_api?
    procedure.expose_legacy_carto_api?
  end

  def geo_position
    if etablissement.present?
      point = ApiAdresse::PointAdapter.new(etablissement.geo_adresse).geocode
    end

    lon = "2.428462"
    lat = "46.538192"
    zoom = "13"

    if point.present?
      lon = point.x.to_s
      lat = point.y.to_s
    end

    { lon: lon, lat: lat, zoom: zoom }
  end

  def unspecified_attestation_champs
    attestation_template = procedure.attestation_template

    if attestation_template&.activated?
      attestation_template.unspecified_champs_for_dossier(self)
    else
      []
    end
  end

  def build_attestation
    if procedure.attestation_template&.activated?
      procedure.attestation_template.attestation_for(self)
    end
  end

  def delete_and_keep_track
    deleted_dossier = DeletedDossier.create_from_dossier(self)
    update(hidden_at: deleted_dossier.deleted_at)

    if en_construction?
      administration_emails = followers_gestionnaires.present? ? followers_gestionnaires.pluck(:email) : procedure.administrateurs.pluck(:email)
      administration_emails.each do |email|
        DossierMailer.notify_deletion_to_administration(deleted_dossier, email).deliver_later
      end
    end
    DossierMailer.notify_deletion_to_user(deleted_dossier, user.email).deliver_later
  end

  def passer_en_instruction!(gestionnaire)
    en_instruction!
    gestionnaire.follow(self)

    log_dossier_operation(gestionnaire, :passer_en_instruction)
  end

  def passer_automatiquement_en_instruction!
    en_instruction!

    log_dossier_operation(nil, :passer_en_instruction, automatic_operation: true)
  end

  def repasser_en_construction!(gestionnaire)
    self.en_instruction_at = nil
    en_construction!

    log_dossier_operation(gestionnaire, :repasser_en_construction)
  end

  def accepter!(gestionnaire, motivation, justificatif = nil)
    self.motivation = motivation
    self.en_instruction_at ||= Time.zone.now
    if justificatif
      self.justificatif_motivation.attach(justificatif)
    end
    accepte!

    if attestation.nil?
      update(attestation: build_attestation)
    end

    NotificationMailer.send_closed_notification(self).deliver_later
    log_dossier_operation(gestionnaire, :accepter)
  end

  def accepter_automatiquement!
    self.en_instruction_at ||= Time.zone.now

    accepte!

    if attestation.nil?
      update(attestation: build_attestation)
    end

    NotificationMailer.send_closed_notification(self).deliver_later
    log_dossier_operation(nil, :accepter, automatic_operation: true)
  end

  def hide!(administration)
    update(hidden_at: Time.zone.now)

    log_administration_dossier_operation(administration, :supprimer)
    DeletedDossier.create_from_dossier(self)
  end

  def refuser!(gestionnaire, motivation, justificatif = nil)
    self.motivation = motivation
    self.en_instruction_at ||= Time.zone.now
    if justificatif
      self.justificatif_motivation.attach(justificatif)
    end
    refuse!

    NotificationMailer.send_refused_notification(self).deliver_later
    log_dossier_operation(gestionnaire, :refuser)
  end

  def classer_sans_suite!(gestionnaire, motivation, justificatif = nil)
    self.motivation = motivation
    self.en_instruction_at ||= Time.zone.now
    if justificatif
      self.justificatif_motivation.attach(justificatif)
    end
    sans_suite!

    NotificationMailer.send_without_continuation_notification(self).deliver_later
    log_dossier_operation(gestionnaire, :classer_sans_suite)
  end

  def check_mandatory_champs
    (champs + champs.select(&:repetition?).flat_map(&:champs))
      .select(&:mandatory_and_blank?)
      .map do |champ|
        "Le champ #{champ.libelle.truncate(200)} doit être rempli."
      end
  end

  private

  def log_dossier_operation(gestionnaire, operation, automatic_operation: false)
    dossier_operation_logs.create(
      gestionnaire: gestionnaire,
      operation: DossierOperationLog.operations.fetch(operation),
      automatic_operation: automatic_operation
    )
  end

  def log_administration_dossier_operation(administration, operation)
    dossier_operation_logs.create(
      administration: administration,
      operation: DossierOperationLog.operations.fetch(operation)
    )
  end

  def update_state_dates
    if en_construction? && !self.en_construction_at
      self.en_construction_at = Time.zone.now
    elsif en_instruction? && !self.en_instruction_at
      self.en_instruction_at = Time.zone.now
    elsif TERMINE.include?(state)
      self.processed_at = Time.zone.now
    end
  end

  def send_dossier_received
    if saved_change_to_state? && en_instruction?
      NotificationMailer.send_dossier_received(self).deliver_later
    end
  end

  def send_draft_notification_email
    if brouillon?
      DossierMailer.notify_new_draft(self).deliver_later
    end
  end

  def send_web_hook
    if saved_change_to_state? && !brouillon? && procedure.web_hook_url
      WebHookJob.perform_later(
        procedure,
        self
      )
    end
  end
end
