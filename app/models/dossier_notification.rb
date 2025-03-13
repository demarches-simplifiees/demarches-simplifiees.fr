class DossierNotification < ApplicationRecord
  belongs_to :groupe_instructeur, optional: true
  belongs_to :instructeur, optional: true
  belongs_to :dossier

  validates :groupe_instructeur_id, presence: true, if: -> { instructeur_id.nil? }
  validates :instructeur_id, presence: true, if: -> { groupe_instructeur_id.nil? }

  enum :notification_type, {
    dossier_depose: 'dossier_depose'
  }

  def self.create_notification(dossier, notification_type, instructeur = nil)
    params = {
      dossier_id: dossier.id,
      notification_type:,
      instructeur_id: instructeur&.id,
      groupe_instructeur_id: dossier.groupe_instructeur_id
    }

    DossierNotification.create_or_find_by!(params) do |notification|
      case notification_type
      when :dossier_depose
        notification.display_at = dossier.depose_at + 7.days
      end
    end
  end

  def self.destroy_notification(dossier, notification_type)
    notification = DossierNotification.find_by(dossier_id: dossier.id, notification_type:)
    notification&.destroy
  end
end
