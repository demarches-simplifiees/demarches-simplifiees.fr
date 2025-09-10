# frozen_string_literal: true

class DossierNotification < ApplicationRecord
  DELAY_DOSSIER_DEPOSE = 7.days

  belongs_to :instructeur
  belongs_to :dossier

  enum :notification_type, {
    dossier_depose: 'dossier_depose',
    dossier_modifie: 'dossier_modifie',
    message: 'message',
    annotation_instructeur: 'annotation_instructeur',
    avis_externe: 'avis_externe',
    attente_correction: 'attente_correction',
    attente_avis: 'attente_avis'
  }

  scope :to_display, -> { where(display_at: ..Time.current) }

  scope :order_by_importance, -> {
    self.sort_by { |notif| notification_types.keys.index(notif.notification_type) }
  }

  scope :type_news, -> { where(notification_type: [:dossier_modifie, :message, :annotation_instructeur, :avis_externe]) }

  def self.create_notification(dossier, notification_type, instructeur: nil, except_instructeur: nil)
    case notification_type
    when :dossier_depose
      if !dossier.procedure.declarative? && !dossier.procedure.sva_svr_enabled?
        instructeur_ids = Array(instructeur&.id.presence || dossier.groupe_instructeur.instructeur_ids)
        display_at = dossier.depose_at + DELAY_DOSSIER_DEPOSE

        instructeur_ids.each do |instructeur_id|
          find_or_create_notification(dossier, notification_type, instructeur_id, display_at:)
        end
      end

    when :dossier_modifie, :message, :attente_correction, :attente_avis, :annotation_instructeur, :avis_externe
      instructeur_ids = Array(instructeur&.id.presence || dossier.followers_instructeur_ids)
      instructeur_ids -= [except_instructeur.id] if except_instructeur.present?

      instructeur_ids.each do |instructeur_id|
        find_or_create_notification(dossier, notification_type, instructeur_id)
      end
    end
  end

  def self.refresh_notifications_instructeur_for_dossier(instructeur, dossier)
    create_notification(dossier, :dossier_modifie, instructeur:) if dossier.last_champ_updated_at.present? && dossier.last_champ_updated_at > dossier.depose_at
    create_notification(dossier, :message, instructeur:) if dossier.commentaires.to_notify(instructeur).present?
    create_notification(dossier, :annotation_instructeur, instructeur:) if dossier.last_champ_private_updated_at.present?
    create_notification(dossier, :avis_externe, instructeur:) if dossier.avis.with_answer.present?
    create_notification(dossier, :attente_correction, instructeur:) if dossier.pending_correction?
    create_notification(dossier, :attente_avis, instructeur:) if dossier.avis.without_answer.present?
  end

  def self.destroy_notifications_instructeur_of_groupe_instructeur(groupe_instructeur, instructeur)
    DossierNotification
      .where(instructeur:)
      .where(dossier_id: groupe_instructeur.dossier_ids)
      .destroy_all
  end

  def self.destroy_notifications_instructeur_of_dossier(instructeur, dossier)
    DossierNotification
      .where(instructeur:, dossier:)
      .destroy_all
  end

  def self.destroy_notifications_by_dossier_and_type(dossier, notification_type)
    DossierNotification
      .where(dossier:, notification_type:)
      .destroy_all
  end

  def self.destroy_notification_by_dossier_and_type_and_instructeur(dossier, notification_type, instructeur)
    DossierNotification
      .find_by(dossier:, notification_type:, instructeur:)
      &.destroy
  end

  def self.notifications_sticker_for_instructeur_procedures(groupe_instructeur_ids, instructeur)
    dossiers_with_news_notification = Dossier
      .where(groupe_instructeur_id: groupe_instructeur_ids)
      .joins(:dossier_notifications)
      .merge(DossierNotification.type_news)
      .where(dossier_notifications: { instructeur: })
      .includes(:procedure)
      .distinct

    dossiers_with_news_notification_by_statut = {
      suivis: dossiers_with_news_notification.by_statut('suivis', instructeur:),
      traites: dossiers_with_news_notification.by_statut('traites')
    }

    dossiers_with_news_notification_by_statut.transform_values do |dossiers|
      dossiers.map { |dossier| dossier.procedure.id }.uniq
    end
  end

  def self.notifications_sticker_for_instructeur_procedure(groupe_instructeur_ids, instructeur)
    dossiers_with_news_notification = Dossier
      .where(groupe_instructeur_id: groupe_instructeur_ids)
      .joins(:dossier_notifications)
      .merge(DossierNotification.type_news)
      .where(dossier_notifications: { instructeur: })
      .distinct

    {
      suivis: dossiers_with_news_notification.by_statut('suivis', instructeur:).exists?,
      traites: dossiers_with_news_notification.by_statut('traites').exists?
    }
  end

  def self.notifications_sticker_for_instructeur_dossier(instructeur, dossier)
    types = {
      demande: :dossier_modifie,
      annotations_privees: :annotation_instructeur,
      avis_externe: :avis_externe,
      messagerie: :message
    }

    return types.transform_values { false } if dossier.archived

    notifications = DossierNotification.where(dossier:, instructeur:)

    types.transform_values { |type| notifications.exists?(notification_type: type) }
  end

  def self.notifications_counts_for_instructeur_procedures(groupe_instructeur_ids, instructeur)
    dossiers = Dossier
      .where(groupe_instructeur_id: groupe_instructeur_ids)
      .visible_by_administration
      .not_archived

    dossier_ids_by_procedure = dossiers
      .joins(:revision)
      .pluck('procedure_revisions.procedure_id', 'dossiers.id')
      .group_by(&:first)
      .transform_values { |v| v.map(&:last) }

    notifications_by_dossier_id = DossierNotification
      .where(dossier: dossiers, instructeur:)
      .to_display
      .group_by(&:dossier_id)

    dossier_ids_by_procedure.transform_values do |dossier_ids|
      notifications = dossier_ids
        .flat_map { |id| notifications_by_dossier_id[id] || [] }
        .group_by(&:notification_type)

      notification_types.keys.index_with { |type| notifications[type]&.count }.compact
    end
  end

  def self.notifications_for_instructeur_procedure(groupe_instructeur_ids, instructeur)
    dossiers = Dossier.where(groupe_instructeur_id: groupe_instructeur_ids)

    dossiers_by_statut = {
      'a-suivre' => dossiers.by_statut('a-suivre'),
      'suivis' => dossiers.by_statut('suivis', instructeur:),
      'traites' => dossiers.by_statut('traites')
    }

    notifications_by_dossier_id = DossierNotification
      .where(dossier: dossiers, instructeur:)
      .to_display
      .group_by(&:dossier_id)

    dossiers_by_statut.filter_map do |statut, dossiers|
      notifications = dossiers
        .flat_map { |d| notifications_by_dossier_id[d.id] || [] }
        .group_by(&:notification_type)

      next if notifications.empty?

      sorted_notifications = notification_types.keys.index_with { |type| notifications[type] }.compact

      [statut, sorted_notifications]
    end.to_h
  end

  def self.notifications_for_instructeur_dossiers(instructeur, dossier_ids)
    DossierNotification
      .joins(:dossier)
      .merge(Dossier.not_archived)
      .where(dossier_id: dossier_ids, instructeur_id: instructeur.id)
      .to_display
      .order_by_importance
      .group_by(&:dossier_id)
  end

  def self.notifications_for_instructeur_dossier(instructeur, dossier)
    return [] if dossier.archived

    DossierNotification
      .where(dossier:, instructeur:)
      .to_display
      .order_by_importance
  end

  def self.notifications_count_for_email_data(groupe_instructeur_ids, instructeur)
    Dossier
      .where(groupe_instructeur_id: groupe_instructeur_ids)
      .visible_by_administration
      .not_archived
      .joins(:dossier_notifications)
      .merge(DossierNotification.type_news)
      .where(dossier_notifications: { instructeur: })
      .distinct
      .count
  end
end

private

def find_or_create_notification(dossier, notification_type, instructeur_id, display_at: Time.current)
  DossierNotification.find_or_create_by!(
    dossier:,
    notification_type:,
    instructeur_id:
  ) do |notification|
    notification.display_at = display_at
  end
end
