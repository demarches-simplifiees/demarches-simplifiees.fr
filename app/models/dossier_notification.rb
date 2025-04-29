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

  scope :to_display, -> { where(display_at: ..Time.current) }

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
      .group_by(&:dossier_id)
  end
end
