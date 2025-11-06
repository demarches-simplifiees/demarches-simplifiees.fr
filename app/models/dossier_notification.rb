# frozen_string_literal: true

class DossierNotification < ApplicationRecord
  DELAY_DOSSIER_DEPOSE = 7.days
  NON_CUSTOMISABLE_TYPE = [:dossier_expirant, :dossier_suppression].freeze

  enum :notification_type, {
    dossier_depose: 'dossier_depose',
    dossier_expirant: 'dossier_expirant',
    dossier_suppression: 'dossier_suppression',
    dossier_modifie: 'dossier_modifie',
    message: 'message',
    annotation_instructeur: 'annotation_instructeur',
    avis_externe: 'avis_externe',
    attente_correction: 'attente_correction',
    attente_avis: 'attente_avis',
  }

  belongs_to :instructeur
  belongs_to :dossier

  scope :to_display, -> {
    where(display_at: ..Time.current)
    .joins(:dossier)
    .where(
      "(NOT dossiers.archived
        AND dossiers.hidden_by_expired_at IS NULL
        AND dossiers.hidden_by_administration_at IS NULL)
      OR (dossiers.archived
        AND dossiers.hidden_by_expired_at IS NULL
        AND dossiers.hidden_by_administration_at IS NULL
        AND dossier_notifications.notification_type = 'dossier_expirant')
      OR ((dossiers.hidden_by_expired_at IS NOT NULL OR dossiers.hidden_by_administration_at IS NOT NULL)
       AND dossier_notifications.notification_type = 'dossier_suppression')"
      )
  }

  scope :order_by_importance, -> {
    self.sort_by { |notif| notification_types.keys.index(notif.notification_type) }
  }

  scope :type_news, -> { where(notification_type: [:dossier_modifie, :message, :annotation_instructeur, :avis_externe]) }

  def self.create_notification(dossier, notification_type, except_instructeur: nil)
    return if NON_CUSTOMISABLE_TYPE.include?(notification_type)

    instructeur_ids = instructeur_to_notify_ids(dossier, notification_type, except_instructeur)

    create_notifications_by_type_for_dossier_instructeurs(dossier, notification_type, instructeur_ids) if instructeur_ids.any?
  end

  def self.create_notifications_for_non_customisable_type(dossiers, notification_type)
    return unless NON_CUSTOMISABLE_TYPE.include?(notification_type)

    instructeur_ids_by_dossier_id = dossiers
        .includes(groupe_instructeur: :instructeurs)
        .map { |d| [d.id, d.groupe_instructeur.instructeur_ids] }
        .to_h

    create_notifications_by_type_for_dossiers_instructeurs(instructeur_ids_by_dossier_id, notification_type)
  end

  def self.refresh_notifications_instructeur_for_followed_dossier(instructeur, dossier)
    destroy_notifications_by_dossier_and_type(dossier, :dossier_depose)

    instructeur_preferences = instructeur_preferences(instructeur, dossier.procedure)

    notification_types_followed = notification_types.keys.map(&:to_sym).filter do |notification_type|
      instructeur_preferences[notification_type] == 'followed'
    end

    return if notification_types_followed.empty?

    notification_types_to_refresh = notification_types_followed.filter do |notification_type|
      instructeur_ids_to_notify_by_notification_type(dossier, notification_type, [instructeur.id]).any?
    end

    create_notifications_for_dossier_instructeur(dossier, notification_types_to_refresh, instructeur.id)
  end

  def self.refresh_notifications_instructeur_for_dossiers(groupe_instructeur_ids, instructeur_id, notification_type, old_preference, new_preference)
    # We use the scope state_not_brouillon rather than visible_by_administration in order to keep notifications up to date
    # on hidden dossiers, so that there is no need to refresh notifications if the dossier is restored.
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

    notification_types_to_refresh.concat(NON_CUSTOMISABLE_TYPE)

    dossiers = groupe_instructeur.dossiers.state_not_brouillon

    notification_types_to_refresh.each do |notification_type|
      dossiers_to_notify = dossiers_to_notify(dossiers, notification_type, instructeur.id)
      create_notifications_by_type_for_instructeur_dossiers(dossiers_to_notify, notification_type, instructeur.id) if dossiers_to_notify.any?
    end
  end

  def self.refresh_notifications_new_instructeurs_for_dossier(instructeur_ids, dossier)
    all_preferences_by_instructeur_id = InstructeursProcedure
      .where(instructeur_id: instructeur_ids, procedure_id: dossier.procedure.id)
      .pluck(:instructeur_id, *InstructeursProcedure::NOTIFICATION_COLUMNS.values)
      .to_h { |instructeur_id, *prefs| [instructeur_id, prefs] }

    instructeur_ids_requesting_notifications_by_type = InstructeursProcedure::NOTIFICATION_COLUMNS.each_with_index.to_h do |(notification_type, _), index|
      instructeur_ids_requesting_notifications = instructeur_ids.filter do |instructeur_id|
        preference = all_preferences_by_instructeur_id.dig(instructeur_id, index) || InstructeursProcedure::DEFAULT_NOTIFICATIONS_PREFERENCES[notification_type]
        preference == 'all'
      end
      [notification_type, instructeur_ids_requesting_notifications]
    end.compact_blank!

    instructeur_ids_requesting_notifications_by_type.each do |notification_type, instructeur_ids|
      instructeur_ids_to_notify = instructeur_ids_to_notify_by_notification_type(dossier, notification_type, instructeur_ids)

      create_notifications_by_type_for_dossier_instructeurs(dossier, notification_type, instructeur_ids_to_notify) if instructeur_ids_to_notify.any?
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
      traites: dossiers_with_news_notification.by_statut('traites'),
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
      traites: dossiers_with_news_notification.by_statut('traites').exists?,
    }
  end

  def self.notifications_sticker_for_instructeur_dossier(instructeur, dossier)
    types = {
      demande: :dossier_modifie,
      annotations_privees: :annotation_instructeur,
      avis_externe: :avis_externe,
      messagerie: :message,
    }

    return types.transform_values { false } if dossier.archived

    notifications = DossierNotification.where(dossier:, instructeur:)

    types.transform_values { |type| notifications.exists?(notification_type: type) }
  end

  def self.notifications_counts_for_instructeur_procedures(groupe_instructeur_ids, instructeur)
    all_dossiers = Dossier.where(groupe_instructeur_id: groupe_instructeur_ids)

    dossiers = all_dossiers.visible_by_administration.or(all_dossiers.by_statut('supprimes'))

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
    notifications = DossierNotification
      .to_display
      .joins(:dossier)
      .where(dossiers: { groupe_instructeur_id: groupe_instructeur_ids }, instructeur:)

    dossier_ids_with_notifications_by_statut = {
      'a-suivre' => notifications.merge(Dossier.by_statut('a-suivre')).group_by(&:notification_type).transform_values { |notifs| notifs.first(10).pluck(:dossier_id) },
      'suivis' => notifications.merge(Dossier.by_statut('suivis', instructeur:)).group_by(&:notification_type).transform_values { |notifs| notifs.first(10).pluck(:dossier_id) },
      'traites' => notifications.merge(Dossier.by_statut('traites')).group_by(&:notification_type).transform_values { |notifs| notifs.first(10).pluck(:dossier_id) },
      'archives' => notifications.merge(Dossier.by_statut('archives')).group_by(&:notification_type).transform_values { |notifs| notifs.first(10).pluck(:dossier_id) },
      'supprimes' => notifications.merge(Dossier.by_statut('supprimes')).group_by(&:notification_type).transform_values { |notifs| notifs.first(10).pluck(:dossier_id) }
    }

    dossiers = Dossier
      .select(:id)
      .where(id: dossier_ids_with_notifications_by_statut.values.flat_map(&:values).flatten.uniq)
      .includes(:etablissement, :individual)
      .index_by(&:id)

    dossier_ids_with_notifications_by_statut.filter_map do |statut, dossier_ids_by_notification_type|
      next if dossier_ids_by_notification_type.empty?

      dossier_ids_by_sorted_notification_type = notification_types.keys.index_with { |type| dossier_ids_by_notification_type[type] }.compact

      dossiers_by_sorted_notification_type = dossier_ids_by_sorted_notification_type
        .transform_values { |dossier_ids| dossiers.values_at(*dossier_ids) }

      [statut, dossiers_by_sorted_notification_type]
    end.to_h
  end

  def self.notifications_for_instructeur_dossiers(instructeur, dossier_ids)
    DossierNotification
      .where(dossier_id: dossier_ids, instructeur_id: instructeur.id)
      .to_display
      .order_by_importance
      .group_by(&:dossier_id)
  end

  def self.notifications_for_instructeur_dossier(instructeur, dossier)
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

  def self.create_notifications_by_type_for_dossier_instructeurs(dossier, notification_type, instructeur_ids)
    display_at = notification_type == :dossier_depose ? (dossier.depose_at + DossierNotification::DELAY_DOSSIER_DEPOSE) : Time.zone.now

    missing_notifications = instructeur_ids.map do |instructeur_id|
      { dossier_id: dossier.id, instructeur_id:, notification_type:, display_at: }
    end

    DossierNotification.insert_all(missing_notifications)
  end

  def self.create_notifications_by_type_for_instructeur_dossiers(dossiers, notification_type, instructeur_id)
    missing_notifications = dossiers.map do |dossier|
      display_at = case notification_type
        when :dossier_depose
          dossier.depose_at + DossierNotification::DELAY_DOSSIER_DEPOSE
        when :dossier_expirant
          dossier.expired_at - Expired::REMAINING_WEEKS_BEFORE_EXPIRATION.weeks
        when :dossier_suppression
          [dossier.hidden_by_administration_at, dossier.hidden_by_expired_at].compact.min
        else
          Time.zone.now
        end

      { dossier_id: dossier.id, instructeur_id:, notification_type:, display_at: }
    end

    DossierNotification.insert_all(missing_notifications)
  end

  def self.create_notifications_for_dossier_instructeur(dossier, notification_types, instructeur_id)
    missing_notifications = notification_types.map do |notification_type|
      display_at = notification_type == :dossier_depose ? (dossier.depose_at + DossierNotification::DELAY_DOSSIER_DEPOSE) : Time.zone.now
      { dossier_id: dossier.id, instructeur_id:, notification_type:, display_at: }
    end

    DossierNotification.insert_all(missing_notifications)
  end

  def self.create_notifications_by_type_for_dossiers_instructeurs(instructeur_ids_by_dossier_id, notification_type)
    missing_notifications = instructeur_ids_by_dossier_id.flat_map do |dossier_id, instructeur_ids|
      instructeur_ids.map do |instructeur_id|
        { dossier_id:, instructeur_id:, notification_type:, display_at: Time.zone.now }
      end
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

  def self.dossiers_to_notify(dossiers, notification_type, instructeur_id)
    case notification_type
    when :dossier_depose
      dossiers
        .select(:id, :state, :depose_at)
        .where(state: :en_construction)
        .without_followers
    when :dossier_expirant
      dossiers
        .select(:id, :revision_id, :expired_at)
        .termine_or_en_construction_close_to_expiration
    when :dossier_suppression
      dossiers
        .select(:id, :hidden_by_administration_at, :hidden_by_expired_at)
        .hidden_by_administration
        .or(dossiers.hidden_by_expired)
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

  def self.instructeur_ids_to_notify_by_notification_type(dossier, notification_type, instructeur_ids)
    case notification_type
    when :dossier_depose
      dossier.en_construction? && dossier.follows.empty? ? instructeur_ids : []
    when :dossier_modifie
      dossier.last_champ_updated_at.present? && dossier.last_champ_updated_at > dossier.depose_at ? instructeur_ids : []
    when :message
      commentaires = dossier
        .commentaires
        .where.not(email: Commentaire::SYSTEM_EMAILS)
        .where(discarded_at: nil)
        .select(:instructeur_id)

      instructeur_ids.filter do |instructeur_id|
        commentaires.any? { |c| c.instructeur_id != instructeur_id || c.instructeur_id == nil }
      end
    when :annotation_instructeur
      dossier.last_champ_private_updated_at.present? ? instructeur_ids : []
    when :avis_externe
      dossier.avis.with_answer.exists? ? instructeur_ids : []
    when :attente_correction
      dossier.pending_correction? ? instructeur_ids : []
    when :attente_avis
      dossier.avis.without_answer.exists? ? instructeur_ids : []
    end
  end
end
