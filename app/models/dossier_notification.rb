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
    params = { dossier_id: dossier.id, notification_type: }

    case notification_type
    when :dossier_depose
      params[:groupe_instructeur_id] = dossier.groupe_instructeur_id
      params[:display_at] = dossier.depose_at + 7.days
    end

    DossierNotification.create!(params)
  end

  def self.destroy_notification(dossier, notification_type)
    notification = DossierNotification.find_by(dossier_id: dossier.id, notification_type:)
    notification&.destroy
  end
end
