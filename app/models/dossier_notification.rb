# frozen_string_literal: true

class DossierNotification < ApplicationRecord
  belongs_to :groupe_instructeur, optional: true
  belongs_to :instructeur, optional: true
  belongs_to :dossier

  validates :groupe_instructeur_id, presence: true, if: -> { instructeur_id.nil? }
  validates :instructeur_id, presence: true, if: -> { groupe_instructeur_id.nil? }

  enum :notification_type, {
    dossier_depose: 'dossier_depose',
    dossier_modifie: 'dossier_modifie',
    message_usager: 'message_usager',
    annotation_instructeur: 'annotation_instructeur',
    avis_externe: 'avis_externe',
    attente_correction: 'attente_correction',
    attente_avis: 'attente_avis'
  }

  scope :to_display, -> { where(display_at: ..Time.current) }

  scope :order_by_importance, -> {
    self.sort_by { |notif| notification_types.keys.index(notif.notification_type) }
  }

  def self.create_notification(dossier, notification_type, instructeur: nil, except_instructeur: nil)
    case notification_type
    when :dossier_depose
      DossierNotification.find_or_create_by!(
        dossier:,
        notification_type:,
        groupe_instructeur_id: dossier.groupe_instructeur_id
      ) do |notification|
        notification.display_at = dossier.depose_at + 7.days
      end

    when :dossier_modifie, :attente_correction, :attente_avis, :message_usager, :annotation_instructeur, :avis_externe
      instructeur_ids = Array(instructeur&.id.presence || dossier.followers_instructeur_ids)
      instructeur_ids -= [except_instructeur.id] if except_instructeur.present?

      instructeur_ids.each do |instructeur_id|
        DossierNotification.find_or_create_by!(
          dossier:,
          notification_type:,
          instructeur_id:
        ) do |notification|
          notification.display_at = Time.current
        end
      end
    end
  end

  def self.update_notifications_groupe_instructeur(previous_groupe_instructeur, new_groupe_instructeur)
    DossierNotification
      .where(groupe_instructeur: previous_groupe_instructeur)
      .update_all(groupe_instructeur_id: new_groupe_instructeur.id)
  end

  def self.refresh_notifications_instructeur_for_dossier(instructeur, dossier)
    create_notification(dossier, :dossier_modifie, instructeur:) if dossier.last_champ_updated_at.present? && dossier.last_champ_updated_at > dossier.depose_at
    create_notification(dossier, :message_usager, instructeur:) if dossier.commentaires.sent_by_user.present?
    create_notification(dossier, :annotation_instructeur, instructeur:) if dossier.champs.private_only.present?
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

  def self.notifications_counts_for_instructeur_procedures(groupe_instructeur_ids, instructeur)
    dossiers = Dossier.where(groupe_instructeur_id: groupe_instructeur_ids)

    dossier_ids_by_procedure = dossiers
      .joins(:revision)
      .pluck('procedure_revisions.procedure_id', 'dossiers.id')
      .group_by(&:first)
      .transform_values { |v| v.map(&:last) }

    notifications_by_dossier_id = DossierNotification
      .where(dossier: dossiers, groupe_instructeur_id: groupe_instructeur_ids)
      .or(DossierNotification.where(dossier: dossiers, instructeur:))
      .to_display
      .order_by_importance
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
      'traites' => dossiers.by_statut('traites'),
      'expirants' => dossiers.by_statut('expirant'),
      'archives' => dossiers.by_statut('archives'),
      'supprimes' => dossiers.by_statut('supprimes')
    }

    notifications_by_dossier_id = DossierNotification
      .where(dossier: dossiers, groupe_instructeur_id: groupe_instructeur_ids)
      .or(DossierNotification.where(dossier: dossiers, instructeur:))
      .to_display
      .order_by_importance
      .group_by(&:dossier_id)

    dossiers_by_statut.filter_map do |statut, dossiers|
      notifs = dossiers.flat_map { |d| notifications_by_dossier_id[d.id] || [] }.group_by(&:notification_type)
      next if notifs.empty?

      sorted_notifs = notification_types.keys.index_with { |type| notifs[type] }.compact

      [statut, sorted_notifs]
    end.to_h
  end

  def self.notifications_for_instructeur_dossiers(groupe_instructeur_ids, instructeur, dossier_ids)
    DossierNotification
      .where(dossier_id: dossier_ids, groupe_instructeur_id: groupe_instructeur_ids)
      .or(DossierNotification.where(dossier_id: dossier_ids, instructeur:))
      .to_display
      .order_by_importance
      .group_by(&:dossier_id)
  end

  def self.notifications_for_instructeur_dossier(instructeur, dossier)
    DossierNotification
      .where(dossier:, groupe_instructeur_id: dossier.groupe_instructeur_id)
      .or(DossierNotification.where(dossier:, instructeur:))
      .to_display
      .order_by_importance
  end
end
