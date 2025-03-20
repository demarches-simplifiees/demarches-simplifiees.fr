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
  end
end
