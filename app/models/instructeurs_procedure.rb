# frozen_string_literal: true

class InstructeursProcedure < ApplicationRecord
  NOTIFICATION_PREFERENCES = ['all', 'followed', 'none'].freeze

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
end
