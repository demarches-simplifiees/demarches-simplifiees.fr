# frozen_string_literal: true

class AddNotificationPreferencesToInstructeursProcedures < ActiveRecord::Migration[7.1]
  def change
    add_column :instructeurs_procedures, :display_dossier_depose_notifications, :string, default: "all", null: false
    add_column :instructeurs_procedures, :display_dossier_modifie_notifications, :string, default: "followed", null: false
    add_column :instructeurs_procedures, :display_message_notifications, :string, default: "followed", null: false
    add_column :instructeurs_procedures, :display_annotation_instructeur_notifications, :string, default: "followed", null: false
    add_column :instructeurs_procedures, :display_avis_externe_notifications, :string, default: "followed", null: false
    add_column :instructeurs_procedures, :display_attente_correction_notifications, :string, default: "followed", null: false
    add_column :instructeurs_procedures, :display_attente_avis_notifications, :string, default: "followed", null: false
  end
end
