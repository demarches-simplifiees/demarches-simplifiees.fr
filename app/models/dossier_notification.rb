class DossierNotification < ApplicationRecord
  belongs_to :groupe_instructeur, optional: true
  belongs_to :instructeur, optional: true
  belongs_to :dossier

  validates :groupe_instructeur_id, presence: true, if: -> { instructeur_id.nil? }
  validates :instructeur_id, presence: true, if: -> { groupe_instructeur_id.nil? }

  enum :notification_type, {
    dossier_depose: 'dossier_depose'
  }

  scope :to_display, -> { where('display_at <= ?', Time.current) }

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

  def self.notifications_for_instructeur_procedure(groupe_instructeur_ids, instructeur)
    dossiers = Dossier.where(groupe_instructeur_id: groupe_instructeur_ids)

    dossiers_by_statut = {
      'a-suivre' => dossiers.by_statut('a-suivre'),
      'suivis' => dossiers.by_statut('suivis', instructeur:),
      'traites' => dossiers.by_statut('traites')
    }

    notifications_by_statut = DossierNotification
      .where(dossier_id: dossiers.select(:id))
      .where(groupe_instructeur_id: groupe_instructeur_ids)
      .or(DossierNotification.where(instructeur_id: instructeur.id))
      .to_display
      .group_by { |notif| dossiers_by_statut.find { |_, dossiers| dossiers.map(&:id).include?(notif.dossier_id) }&.first }

    notifications_by_statut_by_dossier = notifications_by_statut.to_h { |statut, notifs| [statut, notifs.group_by(&:dossier_id)] }
  end

  def self.notifications_for_instructeur_dossiers(groupe_instructeur_ids, instructeur, dossier_ids)
    dossiers = Dossier.where(id: dossier_ids)

    DossierNotification
      .where(dossier_id: dossiers.select(:id))
      .where(groupe_instructeur_id: groupe_instructeur_ids)
      .or(DossierNotification.where(instructeur_id: instructeur.id))
      .to_display
      .group_by(&:dossier_id)
  end

  def self.notifications_for_instructeur_dossier(instructeur, dossier)
    DossierNotification
      .where(dossier_id: dossier.id)
      .where(groupe_instructeur_id: dossier.groupe_instructeur_id)
      .or(DossierNotification.where(instructeur_id: instructeur.id))
      .to_display
      .to_a
  end

  def self.update_notifications_groupe_instructeur(previous_groupe_instructeur, new_groupe_instructeur)
    DossierNotification
      .where(groupe_instructeur_id: previous_groupe_instructeur.id)
      .update_all(groupe_instructeur_id: new_groupe_instructeur.id)
  end

  def badge_class
    case notification_type
    when DossierNotification.notification_types.fetch(:dossier_depose)
      "fr-badge fr-badge--sm fr-badge--warning"
    end
  end

  def badge_text
    case notification_type
    when DossierNotification.notification_types.fetch(:dossier_depose)
      "DÉPOSÉ DEPUIS #{(Time.current - display_at).to_i/1.day} J."
    end
  end
end
