# == Schema Information
#
# Table name: groupe_instructeurs
#
#  id           :bigint           not null, primary key
#  closed       :boolean          default(FALSE)
#  label        :text             not null
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
  has_and_belongs_to_many :exports, dependent: :destroy
  has_and_belongs_to_many :bulk_messages, dependent: :destroy
  has_and_belongs_to_many :batch_operations, dependent: :destroy

  validates :label, presence: true, allow_nil: false
  validates :label, uniqueness: { scope: :procedure }
  validates :closed, acceptance: { accept: [false] }, if: -> { self.procedure.groupe_instructeurs.active.one? }

  before_validation -> { label&.strip! }
  after_save :toggle_routing

  scope :without_group, -> (group) { where.not(id: group) }
  scope :for_api_v2, -> { includes(procedure: [:administrateurs]) }
  scope :active, -> { where(closed: false) }
  scope :closed, -> { where(closed: true) }

  def add(instructeur)
    return if in?(instructeur.groupe_instructeurs)

    default_notification_settings = instructeur.notification_settings(procedure_id)
    instructeur.assign_to.create(groupe_instructeur: self, **default_notification_settings)
  end

  def remove(instructeur)
    return if !in?(instructeur.groupe_instructeurs)

    instructeur.groupe_instructeurs.destroy(self)
    instructeur.follows
      .joins(:dossier)
      .where(dossiers: { groupe_instructeur: self })
      .update_all(unfollowed_at: Time.zone.now)
  end

  def can_delete?
    dossiers.empty? && (procedure.groupe_instructeurs.active.many? || (procedure.groupe_instructeurs.active.one? && closed))
  end

  private

  def toggle_routing
    procedure.update!(routing_enabled: procedure.groupe_instructeurs.active.many?)
  end
end
