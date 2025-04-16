class DossierNotification < ApplicationRecord
  belongs_to :groupe_instructeur, optional: true
  belongs_to :instructeur, optional: true
  belongs_to :dossier

  validates :groupe_instructeur_id, presence: true, if: -> { instructeur_id.nil? }
  validates :instructeur_id, presence: true, if: -> { groupe_instructeur_id.nil? }

  enum :notification_type, {
    dossier_depose: 'dossier_depose',
    dossier_modifie: 'dossier_modifie',
    attente_correction: 'attente_correction'
  }

  scope :to_display, -> { where('display_at <= ?', Time.current) }

  def self.create_notification(dossier, notification_type)
    case notification_type
    when :dossier_depose
      DossierNotification.find_or_create_by!(
        dossier_id: dossier.id,
        notification_type:,
        groupe_instructeur_id: dossier.groupe_instructeur_id
      ) do |notification|
        notification.display_at = dossier.depose_at + 7.days
      end

    when :dossier_modifie, :attente_correction
      instructeur_ids = dossier.followers_instructeur_ids
      if instructeur_ids.present?
        instructeur_ids.each do |instructeur_id|
          DossierNotification.find_or_create_by!(
            dossier_id: dossier.id,
            notification_type:,
            instructeur_id:) do |notification|
              notification.display_at = Time.current
            end
        end
      end
    end
  end

  def self.destroy_notifications_by_dossier_and_type(dossier_id, notification_type)
    DossierNotification
      .where(dossier_id:, notification_type:)
      .destroy_all
  end

  def self.destroy_notification_by_dossier_and_type_and_instructeur(dossier_id, notification_type, instructeur_id)
    DossierNotification
      .find_by(dossier_id:, notification_type:, instructeur_id:)
      &.destroy
  end

  def self.notifications_for_instructeur_procedure(groupe_instructeur_ids, instructeur)
    dossiers = Dossier.where(groupe_instructeur_id: groupe_instructeur_ids)

    dossiers_by_statut = {
      'a-suivre' => dossiers.by_statut('a-suivre'),
      'suivis' => dossiers.by_statut('suivis', instructeur:),
      'traites' => dossiers.by_statut('traites')
    }

    notifications = DossierNotification
      .where(dossier_id: dossiers.select(:id))
      .where(groupe_instructeur_id: groupe_instructeur_ids)
      .or(DossierNotification.where(dossier_id: dossiers.select(:id), instructeur_id: instructeur.id))
      .to_display

    notifications_by_dossier_id = notifications.group_by(&:dossier_id)

    dossiers_by_statut.filter_map do |statut, dossiers|
      notifs = dossiers.flat_map { |d| notifications_by_dossier_id[d.id] || [] }
      next if notifs.empty?

      [statut, notifs.group_by(&:notification_type)]
    end.to_h
  end

  def self.notifications_for_instructeur_dossiers(groupe_instructeur_ids, instructeur, dossier_ids)
    dossiers = Dossier.where(id: dossier_ids)

    DossierNotification
      .where(dossier_id: dossiers.select(:id))
      .where(groupe_instructeur_id: groupe_instructeur_ids)
      .or(DossierNotification.where(dossier_id: dossiers.select(:id), instructeur_id: instructeur.id))
      .to_display
      .group_by(&:dossier_id)
  end

  def self.notifications_for_instructeur_dossier(instructeur, dossier)
    DossierNotification
      .where(dossier_id: dossier.id)
      .where(groupe_instructeur_id: dossier.groupe_instructeur_id)
      .or(DossierNotification.where(dossier_id: dossier.id, instructeur_id: instructeur.id))
      .to_display
      .to_a
  end

  def self.update_notifications_groupe_instructeur(previous_groupe_instructeur, new_groupe_instructeur)
    DossierNotification
      .where(groupe_instructeur_id: previous_groupe_instructeur.id)
      .update_all(groupe_instructeur_id: new_groupe_instructeur.id)
  end

  def self.destroy_notifications_instructeur_of_groupe_instructeur(groupe_instructeur, instructeur)
    DossierNotification
      .where(instructeur_id: instructeur.id)
      .where(dossier_id: groupe_instructeur.dossier_ids)
      .destroy_all
  end

  def self.destroy_notifications_instructeur_of_dossier(instructeur_id, dossier_id)
    DossierNotification
      .where(instructeur_id:, dossier_id:)
      .destroy_all
  end

  def badge_class
    case notification_type
    when DossierNotification.notification_types.fetch(:dossier_depose)
      "fr-badge fr-badge--sm fr-badge--warning"
    when DossierNotification.notification_types.fetch(:dossier_modifie)
      "fr-badge fr-badge--sm fr-badge--new"
    when DossierNotification.notification_types.fetch(:attente_correction)
      "fr-badge fr-badge--sm"
    end
  end

  def badge_text(generic)
    case notification_type
    when DossierNotification.notification_types.fetch(:dossier_depose)
      generic ? "DÉPOSÉ DEPUIS LONGTEMPS" : "DÉPOSÉ DEPUIS #{(Time.current - display_at).to_i/1.day} J."
    when DossierNotification.notification_types.fetch(:dossier_modifie)
      'DOSSIER MODIFIÉ'
    when DossierNotification.notification_types.fetch(:attente_correction)
      'EN ATTENTE DE CORRECTION'
    end
  end
end
