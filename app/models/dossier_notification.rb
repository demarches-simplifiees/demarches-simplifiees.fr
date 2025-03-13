# frozen_string_literal: true

class DossierNotification < ApplicationRecord
  belongs_to :groupe_instructeur, optional: true
  belongs_to :instructeur, optional: true
  belongs_to :dossier

  validates :groupe_instructeur_id, presence: true, if: -> { instructeur_id.nil? }
  validates :instructeur_id, presence: true, if: -> { groupe_instructeur_id.nil? }

  enum :notification_type, {
    dossier_depose: 'dossier_depose'
  }

  def self.create_notification(dossier, notification_type)
    case notification_type
    when :dossier_depose
      DossierNotification.find_or_create_by!(
        dossier:,
        notification_type:,
        groupe_instructeur_id: dossier.groupe_instructeur_id
      ) do |notification|
        notification.display_at = dossier.depose_at + 7.days
      end
    end
  end

  def self.destroy_notifications_by_dossier_and_type(dossier, notification_type)
    DossierNotification
      .where(dossier:, notification_type:)
      .destroy_all
  end
end
