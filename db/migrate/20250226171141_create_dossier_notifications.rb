# frozen_string_literal: true

class CreateDossierNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :dossier_notifications do |t|
      t.references :groupe_instructeur, null: true, foreign_key: true
      t.references :instructeur, null: true, foreign_key: true
      t.references :dossier, null: false, foreign_key: true
      t.string :notification_type, null: false
      t.datetime :display_at
      t.timestamps
    end

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
