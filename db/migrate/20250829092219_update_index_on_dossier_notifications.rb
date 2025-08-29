# frozen_string_literal: true

class UpdateIndexOnDossierNotifications < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_index :dossier_notifications, name: "unique_dossier_groupe_instructeur_notification"

    remove_index :dossier_notifications, name: "unique_dossier_instructeur_notification"

    add_index :dossier_notifications,
              [:dossier_id, :notification_type, :instructeur_id],
              unique: true,
              name: "unique_dossier_instructeur_notification",
              algorithm: :concurrently
  end

  def down
    remove_index :dossier_notifications, name: "unique_dossier_instructeur_notification"

    add_index :dossier_notifications,
      [:dossier_id, :notification_type, :instructeur_id],
      unique: true,
      where: "instructeur_id IS NOT NULL AND groupe_instructeur_id IS NULL",
      name: "unique_dossier_instructeur_notification"

    add_index :dossier_notifications,
      [:dossier_id, :notification_type, :groupe_instructeur_id],
      unique: true,
      where: "groupe_instructeur_id IS NOT NULL AND instructeur_id IS NULL",
      name: "unique_dossier_groupe_instructeur_notification"
  end
end
