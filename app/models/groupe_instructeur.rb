class GroupeInstructeur < ApplicationRecord
  include Logic
  DEFAUT_LABEL = 'défaut'
  belongs_to :procedure, -> { with_discarded }, inverse_of: :groupe_instructeurs, optional: false
  has_many :assign_tos, dependent: :destroy
  has_many :instructeurs, through: :assign_tos
  has_many :dossiers
  has_many :deleted_dossiers
  has_many :batch_operations, through: :dossiers, source: :batch_operations
  has_many :assignments, class_name: 'DossierAssignment', dependent: :nullify, inverse_of: :groupe_instructeur
  has_many :previous_assignments, class_name: 'DossierAssignment', dependent: :nullify, inverse_of: :previous_groupe_instructeur
  has_many :export_templates
  has_and_belongs_to_many :exports, dependent: :destroy

  has_one :defaut_procedure, -> { with_discarded }, class_name: 'Procedure', foreign_key: :defaut_groupe_instructeur_id, dependent: :nullify, inverse_of: :defaut_groupe_instructeur
  has_one :contact_information, dependent: :destroy

  has_one_attached :signature

  SIGNATURE_MAX_SIZE = 1.megabytes
  validates :signature, content_type: ['image/png', 'image/jpg', 'image/jpeg'], size: { less_than: SIGNATURE_MAX_SIZE }

  validates :label, presence: true, allow_nil: false
  validates :label, uniqueness: { scope: :procedure }
  validates :closed, acceptance: { accept: [false] }, if: -> { (self == procedure.defaut_groupe_instructeur) }

  before_validation -> { label&.strip! }

  scope :without_group, -> (group) { where.not(id: group) }
  scope :for_api_v2, -> { includes(procedure: [:administrateurs]) }
  scope :active, -> { where(closed: false) }
  scope :closed, -> { where(closed: true) }
  scope :for_dossiers, -> (dossiers) { joins(:dossiers).where(dossiers: dossiers).distinct(:id) }
  def add(instructeur)
    return if instructeur.nil?
    return if in?(instructeur.groupe_instructeurs)

    default_notification_settings = instructeur.notification_settings(procedure_id)
    instructeur.assign_to.create(groupe_instructeur: self, **default_notification_settings)
  end

  def remove(instructeur)
    return if instructeur.nil?
    return if !in?(instructeur.groupe_instructeurs)

    instructeur.groupe_instructeurs.destroy(self)
    instructeur.follows
      .joins(:dossier)
      .where(dossiers: { groupe_instructeur: self })
      .update_all(unfollowed_at: Time.zone.now)
  end

  def add_instructeurs(ids: [], emails: [])
    instructeurs_to_add, valid_emails, invalid_emails = Instructeur.find_all_by_identifier_with_emails(ids:, emails:)
    not_found_emails = valid_emails - instructeurs_to_add.map(&:email)

    # Send invitations to users without account
    if not_found_emails.present?
      instructeurs_to_add += not_found_emails.map do |email|
        user = User.create_or_promote_to_instructeur(email, SecureRandom.hex, administrateurs: procedure.administrateurs)
        user.invite!
        user.instructeur
      end
    end

    # We dont't want to assign a user to a groupe_instructeur if they are already assigned to it
    instructeurs_to_add -= instructeurs
    instructeurs_to_add.each { add(_1) }

    [instructeurs_to_add, invalid_emails]
  end

  def can_delete?
    dossiers.empty? && (procedure.groupe_instructeurs.active.many? || (procedure.groupe_instructeurs.active.one? && closed))
  end

  def routing_to_configure?
    invalid_rule? || non_unique_rule?
  end

  def invalid_rule?
    !valid_rule?
  end

  def valid_rule?
    return false if routing_rule.nil?
    if [And, Or].include?(routing_rule.class)
      routing_rule.operands.all? { |rule_line| valid_rule_line?(rule_line) }
    else
      valid_rule_line?(routing_rule)
    end
  end

  def valid_rule_line?(rule)
    !rule.is_a?(EmptyOperator) && routing_rule_matches_tdc?(rule)
  end

  def non_unique_rule?
    return false if invalid_rule?
    routing_rule.in?(other_groupe_instructeurs.map(&:routing_rule))
  end

  def groups_with_same_rule
    return if routing_rule.nil?
    other_groupe_instructeurs
      .filter { _1.routing_rule.present? }
      .filter { _1.routing_rule == routing_rule }
      .map(&:label)
      .join(', ')
  end

  def other_groupe_instructeurs
    procedure.groupe_instructeurs - [self]
  end

  def humanized_routing_rule
    routing_rule&.to_s(procedure.active_revision.types_de_champ)
  end

  private

  def routing_rule_matches_tdc?(rule)
    tdcs = procedure.active_revision.types_de_champ_public
    rule.errors(tdcs).blank?
  end

  serialize :routing_rule, LogicSerializer
end
