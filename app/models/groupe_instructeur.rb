# == Schema Information
#
# Table name: groupe_instructeurs
#
#  id           :bigint           not null, primary key
#  closed       :boolean          default(FALSE)
#  label        :text             not null
#  routing_rule :jsonb
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :bigint           not null
#
class GroupeInstructeur < ApplicationRecord
  include Logic
  DEFAUT_LABEL = 'défaut'
  belongs_to :procedure, -> { with_discarded }, inverse_of: :groupe_instructeurs, optional: false
  has_many :assign_tos, dependent: :destroy
  has_many :instructeurs, through: :assign_tos
  has_many :dossiers
  has_many :deleted_dossiers
  has_many :batch_operations, through: :dossiers, source: :batch_operations
  has_and_belongs_to_many :exports, dependent: :destroy
  has_and_belongs_to_many :bulk_messages, dependent: :destroy

  has_one :defaut_procedure, -> { with_discarded }, class_name: 'Procedure', foreign_key: :defaut_groupe_instructeur_id, dependent: :nullify, inverse_of: :defaut_groupe_instructeur

  validates :label, presence: true, allow_nil: false
  validates :label, uniqueness: { scope: :procedure }
  validates :closed, acceptance: { accept: [false] }, if: -> do
    if closed
      (other_groupe_instructeurs.map(&:closed) + [closed]).all?
    else
      false
    end
  end

  before_validation -> { label&.strip! }

  scope :without_group, -> (group) { where.not(id: group) }
  scope :for_api_v2, -> { includes(procedure: [:administrateurs]) }
  scope :active, -> { where(closed: false) }
  scope :closed, -> { where(closed: true) }

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
    rule = routing_rule
    return true if !(rule.is_a?(Logic::Eq) && rule.left.is_a?(Logic::ChampValue) && rule.right.is_a?(Logic::Constant))
    return true if !routing_rule_matches_tdc?
  end

  def non_unique_rule?
    return false if invalid_rule?
    routing_rule.in?(other_groupe_instructeurs.map(&:routing_rule))
  end

  def groups_with_same_rule
    return if routing_rule.nil?
    other_groupe_instructeurs
      .filter { |gi| !gi.routing_rule.nil? && gi.routing_rule.right != empty && gi.routing_rule == routing_rule }
      .map(&:label)
      .join(', ')
  end

  def other_groupe_instructeurs
    procedure.groupe_instructeurs - [self]
  end

  private

  def routing_rule_matches_tdc?
    routing_tdc = procedure.active_revision.types_de_champ.find_by(stable_id: routing_rule.left.stable_id)
    routing_rule.right.value.in?(routing_tdc.options['drop_down_options'])
  end

  serialize :routing_rule, LogicSerializer
end
