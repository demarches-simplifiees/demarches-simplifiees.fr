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

  validates :label, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :label, uniqueness: { scope: :procedure, message: 'existe déjà' }
  validates :closed, acceptance: { accept: [false], message: "Modification impossible : il doit y avoir au moins un groupe instructeur actif sur chaque procédure" }, if: -> { self.procedure.groupe_instructeurs.actif.one? }

  before_validation -> { label&.strip! }
  after_save :toggle_routing

  scope :without_group, -> (group) { where.not(id: group) }
  scope :for_api_v2, -> { includes(procedure: [:administrateurs]) }
  scope :actif, -> { where(closed: false) }

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
    dossiers.empty? && (procedure.groupe_instructeurs.actif.many? || (procedure.groupe_instructeurs.actif.one? && closed))
  end

  private

  def toggle_routing
    procedure.update!(routing_enabled: procedure.groupe_instructeurs.actif.many?)
  end
end
