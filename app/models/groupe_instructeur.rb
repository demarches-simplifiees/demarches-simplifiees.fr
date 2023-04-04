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
  DEFAUT_LABEL = 'défaut'
  belongs_to :procedure, -> { with_discarded }, inverse_of: :groupe_instructeurs, optional: false
  has_many :assign_tos, dependent: :destroy
  has_many :instructeurs, through: :assign_tos
  has_many :dossiers
  has_many :deleted_dossiers
  has_many :batch_operations, through: :dossiers, source: :batch_operations
  has_and_belongs_to_many :exports, dependent: :destroy
  has_and_belongs_to_many :bulk_messages, dependent: :destroy

  validates :label, presence: true, allow_nil: false
  validates :label, uniqueness: { scope: :procedure }
  validates :closed, acceptance: { accept: [false] }, if: -> { closed_changed? && self.procedure.groupe_instructeurs.active.one? }

  before_validation -> { label&.strip! }
  after_save :toggle_routing

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

  private

  def toggle_routing
    procedure.update!(routing_enabled: procedure.groupe_instructeurs.active.many?)
  end

  class RoutingSerializer
    def self.load(routing)
      if routing.present?
        Logic.from_h(routing)
      end
    end

    def self.dump(routing)
      if routing.present?
        routing.to_h
      end
    end
  end

  serialize :routing, RoutingSerializer
end
