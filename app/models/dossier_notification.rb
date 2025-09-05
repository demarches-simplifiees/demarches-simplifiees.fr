# frozen_string_literal: true

class DossierNotification < ApplicationRecord
  DELAY_DOSSIER_DEPOSE = 7.days

  REFRESH_CONDITIONS_BY_TYPE = {
    dossier_depose:          -> (dossier, _) { dossier.en_construction? && dossier.follows.empty? },
    dossier_modifie:         -> (dossier, _) { dossier.last_champ_updated_at.present? && dossier.last_champ_updated_at > dossier.depose_at },
    message:                 -> (dossier, instructeur_id) { dossier.commentaires.to_notify(instructeur_id).present? },
    annotation_instructeur:  -> (dossier, _) { dossier.last_champ_private_updated_at.present? },
    avis_externe:            -> (dossier, _) { dossier.avis.with_answer.present? },
    attente_correction:      -> (dossier, _) { dossier.pending_correction? },
    attente_avis:            -> (dossier, _) { dossier.avis.without_answer.present? }
  }.freeze

  enum :notification_type, {
    dossier_depose: 'dossier_depose',
    dossier_modifie: 'dossier_modifie',
    message: 'message',
    annotation_instructeur: 'annotation_instructeur',
    avis_externe: 'avis_externe',
    attente_correction: 'attente_correction',
    attente_avis: 'attente_avis'
  }

  belongs_to :instructeur
  belongs_to :dossier

  scope :to_display, -> { where(display_at: ..Time.current) }

  scope :order_by_importance, -> {
    self.sort_by { |notif| notification_types.keys.index(notif.notification_type) }
  }

  scope :type_news, -> { where(notification_type: [:dossier_modifie, :message, :annotation_instructeur, :avis_externe]) }

  def self.create_notification(dossier, notification_type, except_instructeur: nil)
    instructeur_ids = instructeur_to_notify_ids(dossier, notification_type, except_instructeur)

    instructeur_ids.each do |instructeur_id|
      find_or_create_notification(dossier, notification_type, instructeur_id)
    end
  end

  def self.refresh_notifications_instructeur_for_followed_dossier(instructeur, dossier)
    destroy_notifications_by_dossier_and_type(dossier, :dossier_depose)

    instructeur_preferences = instructeur_preferences(instructeur, dossier.procedure)

    notification_types_followed = notification_types.keys.map(&:to_sym).filter do |notification_type|
      instructeur_preferences[notification_type] == "followed"
    end

    return if notification_types_followed.empty?

    notification_types_followed.each do |notification_type|
      find_or_create_notification(dossier, notification_type, instructeur.id) if REFRESH_CONDITIONS_BY_TYPE[notification_type].call(dossier, instructeur.id)
    end
  end

  def self.refresh_notifications_instructeur_for_dossiers(all_dossiers, followed_dossiers, non_followed_dossiers, instructeur_id, notification_type, old_preference, new_preference)
    case [old_preference, new_preference]
    when ['all', 'none'], ['followed', 'none']
      destroy_notifications_by_dossiers_and_type_and_instructeur(all_dossiers, notification_type, instructeur_id)
    when ['all', 'followed']
      destroy_notifications_by_dossiers_and_type_and_instructeur(non_followed_dossiers, notification_type, instructeur_id)
    when ['none', 'all']
      refresh_notifications_instructeur_for_dossiers_and_type(all_dossiers, notification_type, instructeur_id)
    when ['followed', 'all']
      refresh_notifications_instructeur_for_dossiers_and_type(non_followed_dossiers, notification_type, instructeur_id)
    when ['none', 'followed']
      refresh_notifications_instructeur_for_dossiers_and_type(followed_dossiers, notification_type, instructeur_id)
    end
  end

  def self.destroy_notifications_instructeur_of_groupe_instructeur(groupe_instructeur, instructeur)
    DossierNotification
      .where(instructeur:)
      .where(dossier_id: groupe_instructeur.dossier_ids)
      .destroy_all
  end

  def self.destroy_notifications_instructeur_of_unfollowed_dossier(instructeur, dossier)
    instructeur_preferences = instructeur_preferences(instructeur, dossier.procedure)

    notification_types_to_destroy = notification_types.keys.map(&:to_sym).reject do |notification_type|
      instructeur_preferences[notification_type] == "all"
    end

    return if notification_types_to_destroy.empty?

    DossierNotification
      .where(instructeur:, dossier:, notification_type: notification_types_to_destroy)
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

  private

  def self.find_or_create_notification(dossier, notification_type, instructeur_id)
    display_at = notification_type == :dossier_depose ? (dossier.depose_at + DossierNotification::DELAY_DOSSIER_DEPOSE) : Time.zone.now

    DossierNotification.find_or_create_by!(
      dossier:,
      notification_type:,
      instructeur_id:
    ) do |notification|
      notification.display_at = display_at
    end
  end

  def self.instructeur_preferences(instructeur, procedure)
    if (instructeur_procedure = InstructeursProcedure.find_by(instructeur:, procedure:))
      instructeur_procedure.notification_preferences
    else
      InstructeursProcedure::DEFAULT_NOTIFICATIONS_PREFERENCES
    end
  end

  def self.instructeur_to_notify_ids(dossier, notification_type, except_instructeur)
    instructeur_ids = dossier.groupe_instructeur.instructeur_ids
    instructeur_ids -= [except_instructeur.id] if except_instructeur.present?

    followers_instructeur_ids = dossier.followers_instructeur_ids

    preference_by_instructeur_id = InstructeursProcedure
      .where(instructeur_id: instructeur_ids, procedure_id: dossier.procedure.id)
      .pluck(:instructeur_id, "display_#{notification_type}_notifications")
      .to_h

    instructeur_ids.filter do |instructeur_id|
      preference = preference_by_instructeur_id[instructeur_id] || InstructeursProcedure::DEFAULT_NOTIFICATIONS_PREFERENCES[notification_type]

      if followers_instructeur_ids.include?(instructeur_id)
        ['followed', 'all'].include?(preference)
      else
        preference == "all"
      end
    end
  end

  def self.destroy_notifications_by_dossiers_and_type_and_instructeur(dossiers, notification_type, instructeur_id)
    DossierNotification
      .where(dossier_id: dossiers, notification_type:, instructeur_id:)
      .destroy_all
  end

  def self.refresh_notifications_instructeur_for_dossiers_and_type(dossiers, notification_type, instructeur_id)
    missing_notifications = dossiers.filter_map do |dossier|
      if DossierNotification::REFRESH_CONDITIONS_BY_TYPE[notification_type].call(dossier, instructeur_id)
        display_at = notification_type == :dossier_depose ? (dossier.depose_at + DossierNotification::DELAY_DOSSIER_DEPOSE) : Time.zone.now
        { dossier_id: dossier.id, instructeur_id:, notification_type:, display_at: }
      end
    end
    DossierNotification.insert_all(missing_notifications) if missing_notifications.size.positive?
  end
end
