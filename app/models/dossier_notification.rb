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

    create_notifications_by_type_for_dossier_instructeurs(dossier, notification_type, instructeur_ids) if instructeur_ids.any?
  end

  def self.refresh_notifications_instructeur_for_dossier_by_choice(instructeur, dossier, choice)
    instructeur_preferences = instructeur_preferences(instructeur, dossier.procedure)

    notification_types_to_refresh = notification_types.keys.map(&:to_sym).filter do |notification_type|
      instructeur_preferences[notification_type] == choice
    end

    return if notification_types_to_refresh.empty?

    notification_types_to_refresh.each do |notification_type|
      find_or_create_notification(dossier, notification_type, instructeur.id) if REFRESH_CONDITIONS_BY_TYPE[notification_type].call(dossier, instructeur.id)
    end
  end

  def self.refresh_notifications_instructeur_for_followed_dossier(instructeur, dossier)
    destroy_notifications_by_dossier_and_type(dossier, :dossier_depose)
    refresh_notifications_instructeur_for_dossier_by_choice(instructeur, dossier, 'followed')
  end

  def self.refresh_notifications_instructeur_for_dossiers(groupe_instructeur_ids, instructeur_id, notification_type, old_preference, new_preference)
    all_dossiers = Dossier.where(groupe_instructeur_id: groupe_instructeur_ids).state_not_brouillon
    followed_dossiers = all_dossiers.joins(:follows).where(follows: { instructeur_id: }).distinct
    non_followed_dossiers = all_dossiers.where.not(id: followed_dossiers)

    case [old_preference, new_preference]
    when ['all', 'none'], ['followed', 'none']
      destroy_notifications_by_type_for_instructeur_dossiers(all_dossiers, notification_type, instructeur_id)
    when ['all', 'followed']
      destroy_notifications_by_type_for_instructeur_dossiers(non_followed_dossiers, notification_type, instructeur_id)
    when ['none', 'all']
      all_dossiers_to_notify = dossiers_to_notify(all_dossiers, notification_type, instructeur_id)
      create_notifications_by_type_for_instructeur_dossiers(all_dossiers_to_notify, notification_type, instructeur_id) if all_dossiers_to_notify.any?
    when ['followed', 'all']
      non_followed_dossiers_to_notify = dossiers_to_notify(non_followed_dossiers, notification_type, instructeur_id)
      create_notifications_by_type_for_instructeur_dossiers(non_followed_dossiers_to_notify, notification_type, instructeur_id) if non_followed_dossiers_to_notify.any?
    when ['none', 'followed']
      followed_dossiers_to_notify = dossiers_to_notify(followed_dossiers, notification_type, instructeur_id)
      create_notifications_by_type_for_instructeur_dossiers(followed_dossiers_to_notify, notification_type, instructeur_id) if followed_dossiers_to_notify.any?
    end
  end

  def self.refresh_notifications_new_instructeur_for_dossiers(groupe_instructeur, instructeur)
    instructeur_preferences = instructeur_preferences(instructeur, groupe_instructeur.procedure)

    notification_types_to_refresh = notification_types.keys.map(&:to_sym).filter do |notification_type|
      instructeur_preferences[notification_type] == 'all'
    end

    return if notification_types_to_refresh.empty?

    dossiers = groupe_instructeur.dossiers.state_not_brouillon

    notification_types_to_refresh.each do |notification_type|
      dossiers_to_notify = dossiers_to_notify(dossiers, notification_type, instructeur.id)
      create_notifications_by_type_for_instructeur_dossiers(dossiers_to_notify, notification_type, instructeur.id) if dossiers_to_notify.any?
    end
  end

  def self.destroy_notifications_instructeur_of_groupe_instructeur(groupe_instructeur, instructeur)
    DossierNotification
      .where(instructeur:)
      .where(dossier_id: groupe_instructeur.dossier_ids)
      .delete_all
  end

  def self.destroy_notifications_instructeurs_of_old_dossier(instructeur_ids, dossier)
    DossierNotification
      .where(instructeur_id: instructeur_ids, dossier:)
      .delete_all
  end

  def self.destroy_notifications_instructeur_of_unfollowed_dossier(instructeur, dossier)
    instructeur_preferences = instructeur_preferences(instructeur, dossier.procedure)

    notification_types_to_destroy = notification_types.keys.map(&:to_sym).reject do |notification_type|
      instructeur_preferences[notification_type] == "all"
    end

    return if notification_types_to_destroy.empty?

    DossierNotification
      .where(instructeur:, dossier:, notification_type: notification_types_to_destroy)
      .delete_all
  end

  def self.destroy_notifications_by_dossier_and_type(dossier, notification_type)
    DossierNotification
      .where(dossier:, notification_type:)
      .delete_all
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
      a_suivre: dossiers_with_news_notification.by_statut('a-suivre'),
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
      a_suivre: dossiers_with_news_notification.by_statut('a-suivre').exists?,
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

  def self.create_notifications_by_type_for_dossier_instructeurs(dossier, notification_type, instructeur_ids)
    display_at = notification_type == :dossier_depose ? (dossier.depose_at + DossierNotification::DELAY_DOSSIER_DEPOSE) : Time.zone.now

    missing_notifications = instructeur_ids.map do |instructeur_id|
      { dossier_id: dossier.id, instructeur_id:, notification_type:, display_at: }
    end

    DossierNotification.insert_all(missing_notifications)
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

  def self.destroy_notifications_by_type_for_instructeur_dossiers(dossiers, notification_type, instructeur_id)
    DossierNotification
      .where(dossier_id: dossiers, notification_type:, instructeur_id:)
      .delete_all
  end

  def self.create_notifications_by_type_for_instructeur_dossiers(dossiers, notification_type, instructeur_id)
    missing_notifications = dossiers.map do |dossier|
      display_at = notification_type == :dossier_depose ? (dossier.depose_at + DossierNotification::DELAY_DOSSIER_DEPOSE) : Time.zone.now
      { dossier_id: dossier.id, instructeur_id:, notification_type:, display_at: }
    end
    DossierNotification.insert_all(missing_notifications)
  end

  def self.dossiers_to_notify(dossiers, notification_type, instructeur_id)
    case notification_type
    when :dossier_depose
      dossiers
        .select(:id, :state, :depose_at)
        .where(state: :en_construction)
        .without_followers
    when :dossier_modifie
      dossiers
        .select(:id, :last_champ_updated_at, :depose_at)
        .where.not(last_champ_updated_at: nil)
        .where("last_champ_updated_at > depose_at")
    when :message
      dossiers
        .select(:id)
        .joins(:commentaires)
        .merge(Commentaire.to_notify(instructeur_id))
        .distinct
    when :annotation_instructeur
      dossiers
        .select(:id, :last_champ_private_updated_at)
        .where.not(last_champ_private_updated_at: nil)
    when :avis_externe
      dossiers
        .select(:id)
        .joins(:avis)
        .merge(Avis.with_answer)
        .distinct
    when :attente_correction
      dossiers
        .select(:id)
        .with_pending_corrections
    when :attente_avis
      dossiers
        .select(:id)
        .joins(:avis)
        .merge(Avis.without_answer)
        .distinct
    end
  end
end
