# frozen_string_literal: true

class InstructeursProcedure < ApplicationRecord
  NOTIFICATION_PREFERENCES = ['all', 'followed', 'none'].freeze

  DEFAULT_NOTIFICATIONS_PREFERENCES = {
    dossier_depose: 'all',
    dossier_modifie: 'followed',
    message: 'followed',
    annotation_instructeur: 'followed',
    avis_externe: 'followed',
    attente_correction: 'followed',
    attente_avis: 'followed'
  }.freeze

  NOTIFICATION_COLUMNS = {
    dossier_depose: 'display_dossier_depose_notifications',
    dossier_modifie: 'display_dossier_modifie_notifications',
    message: 'display_message_notifications',
    annotation_instructeur: 'display_annotation_instructeur_notifications',
    avis_externe: 'display_avis_externe_notifications',
    attente_correction: 'display_attente_correction_notifications',
    attente_avis: 'display_attente_avis_notifications'
  }.freeze

  belongs_to :instructeur
  belongs_to :procedure

  validates :display_dossier_depose_notifications, inclusion: { in: NOTIFICATION_PREFERENCES - ['followed'] }
  validates :display_dossier_modifie_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }
  validates :display_message_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }
  validates :display_annotation_instructeur_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }
  validates :display_avis_externe_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }
  validates :display_attente_correction_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }
  validates :display_attente_avis_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }

  def self.update_instructeur_procedures_positions(instructeur, ordered_procedure_ids)
    procedure_id_position = ordered_procedure_ids.reverse.each.with_index.to_h
    InstructeursProcedure.transaction do
      procedure_id_position.each do |procedure_id, position|
        InstructeursProcedure.where(procedure_id:, instructeur:).update(position:)
      end
    end
  end

  def notification_preferences
    NOTIFICATION_COLUMNS.transform_values do |column|
      self.public_send(column)
    end
  end

  def notification_preference_for(notification_type)
    self.public_send(NOTIFICATION_COLUMNS[notification_type])
  end

  def refresh_notifications(groupe_instructeur_ids, old_preferences, new_preferences)
    return if old_preferences == new_preferences

    old_preferences.keys.each do |notification_type|
      if old_preferences[notification_type] != new_preferences[notification_type]
        DossierNotification.refresh_notifications_instructeur_for_dossiers(
          groupe_instructeur_ids,
          instructeur_id,
          notification_type,
          old_preferences[notification_type],
          new_preferences[notification_type]
        )
      end
    end
  end
end
