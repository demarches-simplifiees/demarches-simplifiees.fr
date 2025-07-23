# frozen_string_literal: true

class InstructeursProcedure < ApplicationRecord
  belongs_to :instructeur
  belongs_to :procedure

  NOTIFICATION_PREFERENCES = ['all', 'followed', 'none'].freeze

  validates :display_dossier_depose_notifications, inclusion: { in: NOTIFICATION_PREFERENCES - ['followed'] }
  validates :display_dossier_modifie_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }
  validates :display_message_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }
  validates :display_annotation_instructeur_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }
  validates :display_avis_externe_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }
  validates :display_attente_correction_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }
  validates :display_attente_avis_notifications, inclusion: { in: NOTIFICATION_PREFERENCES }
end
